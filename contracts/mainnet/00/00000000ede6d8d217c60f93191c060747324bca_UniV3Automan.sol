// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "solady/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager as INPM} from "@aperture_finance/uni-v3-lib/src/interfaces/INonfungiblePositionManager.sol";
import {LiquidityAmounts} from "@aperture_finance/uni-v3-lib/src/LiquidityAmounts.sol";
import {NPMCaller, Position} from "@aperture_finance/uni-v3-lib/src/NPMCaller.sol";
import {PoolAddress, PoolKey} from "@aperture_finance/uni-v3-lib/src/PoolAddress.sol";
import {Payments, SwapRouter, UniV3Immutables} from "./base/SwapRouter.sol";
import {IUniV3Automan} from "./interfaces/IUniV3Automan.sol";
import {FullMath, OptimalSwap, TickMath, V3PoolCallee} from "./libraries/OptimalSwap.sol";

/// @title Automation manager for Uniswap v3 liquidity with built-in optimal swap algorithm
/// @author Aperture Finance
/// @dev The validity of the tokens in `poolKey` and the pool contract computed from it is not checked here.
/// However if they are invalid, pool `swap`, `burn` and `mint` will revert here or in `NonfungiblePositionManager`.
contract UniV3Automan is Ownable, UniV3Immutables, Payments, SwapRouter, IUniV3Automan {
    using SafeTransferLib for address;
    using FullMath for uint256;
    using TickMath for int24;

    uint256 internal constant MAX_FEE_PIPS = 1e18;

    /************************************************
     *  STATE VARIABLES
     ***********************************************/

    struct FeeConfig {
        /// @notice The address that receives fees
        /// @dev It is stored in the lower 160 bits of the slot
        address feeCollector;
        /// @notice The maximum fee percentage that can be charged for a transaction
        /// @dev It is stored in the upper 96 bits of the slot
        uint96 feeLimitPips;
    }

    FeeConfig public feeConfig;
    /// @notice The address list that can perform automation
    mapping(address => bool) public isController;
    /// @notice The list of whitelisted routers
    mapping(address => bool) public isWhiteListedSwapRouter;

    constructor(INPM nonfungiblePositionManager, address owner_) UniV3Immutables(nonfungiblePositionManager) {
        require(owner_ != address(0));
        _transferOwnership(owner_);
    }

    /************************************************
     *  ACCESS CONTROL
     ***********************************************/

    /// @dev Reverts if the caller is not a controller or the position owner
    function checkAuthorizedForToken(uint256 tokenId) internal view {
        if (isController[msg.sender]) return;
        if (msg.sender != NPMCaller.ownerOf(npm, tokenId)) revert NotApproved();
    }

    /// @dev Reverts if the fee is greater than the limit
    function checkFeeSanity(uint256 feePips) internal view {
        if (feePips > feeConfig.feeLimitPips) revert FeeLimitExceeded();
    }

    /// @dev Reverts if the router is not whitelisted
    /// @param swapData The address of the external router and call data
    function checkRouter(bytes calldata swapData) internal view returns (address router) {
        assembly {
            router := shr(96, calldataload(swapData.offset))
        }
        if (!isWhiteListedSwapRouter[router]) revert NotWhitelistedRouter();
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /// @notice Set the fee limit and collector
    /// @param _feeConfig The new fee configuration
    function setFeeConfig(FeeConfig calldata _feeConfig) external onlyOwner {
        require(_feeConfig.feeLimitPips < MAX_FEE_PIPS);
        require(_feeConfig.feeCollector != address(0));
        feeConfig = _feeConfig;
        emit FeeConfigSet(_feeConfig.feeCollector, _feeConfig.feeLimitPips);
    }

    /// @notice Set addresses that can perform automation
    function setControllers(address[] calldata controllers, bool[] calldata statuses) external onlyOwner {
        uint256 len = controllers.length;
        require(len == statuses.length);
        unchecked {
            for (uint256 i; i < len; ++i) {
                isController[controllers[i]] = statuses[i];
            }
        }
        emit ControllersSet(controllers, statuses);
    }

    /// @notice Set whitelisted swap routers
    /// @dev If `NonfungiblePositionManager` is a whitelisted router, this contract may approve arbitrary address to
    /// spend NFTs it has been approved of.
    /// @dev If an ERC20 token is whitelisted as a router, `transferFrom` may be called to drain tokens approved
    /// to this contract during `mintOptimal` or `increaseLiquidityOptimal`.
    /// @dev If a malicious router is whitelisted and called without slippage control, the caller may lose tokens in an
    /// external swap. The router can't, however, drain ERC20 or ERC721 tokens which have been approved by other users
    /// to this contract. Because this contract doesn't contain `transferFrom` with random `from` address like that in
    /// SushiSwap's [`RouteProcessor2`](https://rekt.news/sushi-yoink-rekt/).
    function setSwapRouters(address[] calldata routers, bool[] calldata statuses) external onlyOwner {
        uint256 len = routers.length;
        require(len == statuses.length);
        unchecked {
            for (uint256 i; i < len; ++i) {
                address router = routers[i];
                if (statuses[i]) {
                    // revert if `router` is `NonfungiblePositionManager`
                    if (router == address(npm)) revert InvalidSwapRouter();
                    // revert if `router` is an ERC20 or not a contract
                    (bool success, ) = router.call(abi.encodeWithSelector(IERC20.approve.selector, address(npm), 0));
                    if (success) revert InvalidSwapRouter();
                    isWhiteListedSwapRouter[router] = true;
                } else {
                    delete isWhiteListedSwapRouter[router];
                }
            }
        }
        emit SwapRoutersSet(routers, statuses);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /// @dev Wrapper around `INonfungiblePositionManager.positions`
    /// @param tokenId The ID of the token that represents the position
    /// @return Position token0 The address of the token0 for a specific pool
    /// token1 The address of the token1 for a specific pool
    /// feeTier The fee tier of the pool
    /// tickLower The lower end of the tick range for the position
    /// tickUpper The higher end of the tick range for the position
    /// liquidity The liquidity of the position
    function _positions(uint256 tokenId) internal view returns (Position memory) {
        return NPMCaller.positions(npm, tokenId);
    }

    /// @notice Cast `Position` to `PoolKey`
    /// @dev Solidity assigns free memory to structs when they are declared, which is unnecessary in this case.
    /// But there is nothing we can do unless the memory of a struct is only assigned when using the `new` keyword.
    function castPoolKey(Position memory pos) internal pure returns (PoolKey memory poolKey) {
        assembly ("memory-safe") {
            // `PoolKey` is a subset of `Position`
            poolKey := pos
        }
    }

    /// @notice Cast `MintParams` to `PoolKey`
    function castPoolKey(INPM.MintParams memory params) internal pure returns (PoolKey memory poolKey) {
        assembly ("memory-safe") {
            // `PoolKey` is a subset of `MintParams`
            poolKey := params
        }
    }

    /// @inheritdoc IUniV3Automan
    function getOptimalSwap(
        V3PoolCallee pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256 amountIn, uint256 amountOut, bool zeroForOne, uint160 sqrtPriceX96) {
        return OptimalSwap.getOptimalSwap(pool, tickLower, tickUpper, amount0Desired, amount1Desired);
    }

    /************************************************
     *  INTERNAL ACTIONS
     ***********************************************/

    /// @dev Make a swap using a v3 pool directly or through an external router
    /// @param poolKey The pool key containing the token addresses and fee tier
    /// @param amountIn The amount of token to be swapped
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param swapData The address of the external router and call data
    /// @return amountOut The amount of token received after swap
    function _swap(
        PoolKey memory poolKey,
        uint256 amountIn,
        bool zeroForOne,
        bytes calldata swapData
    ) private returns (uint256 amountOut) {
        if (swapData.length == 0) {
            amountOut = _poolSwap(poolKey, PoolAddress.computeAddressSorted(factory, poolKey), amountIn, zeroForOne);
        } else {
            address router = checkRouter(swapData);
            amountOut = _routerSwap(poolKey, router, zeroForOne, swapData);
        }
    }

    /// @dev Swap tokens to the optimal ratio to add liquidity and approve npm to spend
    /// @param poolKey The pool key containing the token addresses and fee tier
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount0Desired The desired amount of token0 to be spent
    /// @param amount1Desired The desired amount of token1 to be spent
    /// @return amount0 The amount of token0 after swap
    /// @return amount1 The amount of token1 after swap
    function _optimalSwap(
        PoolKey memory poolKey,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired,
        bytes calldata swapData
    ) private returns (uint256 amount0, uint256 amount1) {
        if (swapData.length == 0) {
            // Swap with the v3 pool directly
            (amount0, amount1) = _optimalSwapWithPool(poolKey, tickLower, tickUpper, amount0Desired, amount1Desired);
        } else {
            // Swap with a whitelisted router
            address router = checkRouter(swapData);
            (amount0, amount1) = _optimalSwapWithRouter(
                poolKey,
                router,
                tickLower,
                tickUpper,
                amount0Desired,
                amount1Desired,
                swapData
            );
        }
        // Approve the v3 position manager to spend the tokens
        if (amount0 != 0) poolKey.token0.safeApprove(address(npm), amount0);
        if (amount1 != 0) poolKey.token1.safeApprove(address(npm), amount1);
    }

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function _burn(uint256 tokenId) private {
        return NPMCaller.burn(npm, tokenId);
    }

    /// @notice Collects tokens owed to a specific position
    /// @param tokenId The ID of the NFT for which tokens are being collected
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function _collect(uint256 tokenId, address recipient) private returns (uint256 amount0, uint256 amount1) {
        return NPMCaller.collect(npm, tokenId, recipient);
    }

    /// @dev Internal function to mint and refund
    function _mint(
        INPM.MintParams memory params
    ) private returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        (tokenId, liquidity, amount0, amount1) = NPMCaller.mint(npm, params);
        address recipient = params.recipient;
        uint256 amount0Desired = params.amount0Desired;
        uint256 amount1Desired = params.amount1Desired;
        // Refund any surplus value to the recipient
        unchecked {
            if (amount0 < amount0Desired) {
                address token0 = params.token0;
                token0.safeApprove(address(npm), 0);
                refund(token0, recipient, amount0Desired - amount0);
            }
            if (amount1 < amount1Desired) {
                address token1 = params.token1;
                token1.safeApprove(address(npm), 0);
                refund(token1, recipient, amount1Desired - amount1);
            }
        }
    }

    /// @dev Internal increase liquidity abstraction
    function _increaseLiquidity(
        INPM.IncreaseLiquidityParams memory params,
        address token0,
        address token1
    ) private returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        (liquidity, amount0, amount1) = NPMCaller.increaseLiquidity(npm, params);
        uint256 amount0Desired = params.amount0Desired;
        uint256 amount1Desired = params.amount1Desired;
        // Refund any surplus value to the caller
        unchecked {
            if (amount0 < amount0Desired) {
                token0.safeApprove(address(npm), 0);
                refund(token0, msg.sender, amount0Desired - amount0);
            }
            if (amount1 < amount1Desired) {
                token1.safeApprove(address(npm), 0);
                refund(token1, msg.sender, amount1Desired - amount1);
            }
        }
    }

    /// @dev Collect the tokens owed, deduct transaction fees in both tokens and send it to the fee collector
    /// @param amount0Principal The principal amount of token0 used to calculate the fee
    /// @param amount1Principal The principal amount of token1 used to calculate the fee
    /// @return amount0 The amount of token0 after fees
    /// @return amount1 The amount of token1 after fees
    function _collectMinusFees(
        uint256 tokenId,
        address token0,
        address token1,
        uint256 amount0Principal,
        uint256 amount1Principal,
        uint256 feePips
    ) private returns (uint256, uint256) {
        // Collect the tokens owed then deduct transaction fees
        (uint256 amount0Collected, uint256 amount1Collected) = _collect(tokenId, address(this));
        // Calculations outside mulDiv won't overflow.
        unchecked {
            uint256 fee0 = amount0Principal.mulDiv(feePips, MAX_FEE_PIPS);
            uint256 fee1 = amount1Principal.mulDiv(feePips, MAX_FEE_PIPS);
            if (amount0Collected < fee0 || amount1Collected < fee1) revert InsufficientAmount();
            address _feeCollector = feeConfig.feeCollector;
            if (fee0 != 0) {
                amount0Collected -= fee0;
                refund(token0, _feeCollector, fee0);
            }
            if (fee1 != 0) {
                amount1Collected -= fee1;
                refund(token1, _feeCollector, fee1);
            }
        }
        return (amount0Collected, amount1Collected);
    }

    /// @dev Collect the tokens owed, deduct transaction fees in both tokens and send it to the fee collector
    /// @param amount0Delta The change in token0 used to calculate the fee
    /// @param amount1Delta The change in token1 used to calculate the fee
    /// @param liquidityDelta The change in liquidity used to calculate the principal
    /// @return amount0 The amount of token0 after fees
    /// @return amount1 The amount of token1 after fees
    function _collectMinusFees(
        Position memory pos,
        uint256 tokenId,
        uint256 amount0Delta,
        uint256 amount1Delta,
        uint128 liquidityDelta,
        uint256 feePips
    ) private returns (uint256, uint256) {
        (uint256 amount0Collected, uint256 amount1Collected) = _collect(tokenId, address(this));
        // Calculations outside mulDiv won't overflow.
        unchecked {
            uint256 fee0;
            uint256 fee1;
            {
                uint256 numerator = feePips * pos.liquidity;
                uint256 denominator = MAX_FEE_PIPS * liquidityDelta;
                fee0 = amount0Delta.mulDiv(numerator, denominator);
                fee1 = amount1Delta.mulDiv(numerator, denominator);
            }
            if (amount0Collected < fee0 || amount1Collected < fee1) revert InsufficientAmount();
            address _feeCollector = feeConfig.feeCollector;
            if (fee0 != 0) {
                amount0Collected -= fee0;
                refund(pos.token0, _feeCollector, fee0);
            }
            if (fee1 != 0) {
                amount1Collected -= fee1;
                refund(pos.token1, _feeCollector, fee1);
            }
        }
        return (amount0Collected, amount1Collected);
    }

    /// @dev Internal decrease liquidity abstraction
    function _decreaseLiquidity(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips
    ) private returns (uint256 amount0, uint256 amount1) {
        uint256 tokenId = params.tokenId;
        Position memory pos = _positions(tokenId);
        // Slippage check is delegated to `NonfungiblePositionManager` via `DecreaseLiquidityParams`.
        (uint256 amount0Delta, uint256 amount1Delta) = NPMCaller.decreaseLiquidity(npm, params);
        // Collect the tokens owed and deduct transaction fees
        (amount0, amount1) = _collectMinusFees(pos, tokenId, amount0Delta, amount1Delta, params.liquidity, feePips);
        // Send the remaining amounts to the position owner
        address owner = NPMCaller.ownerOf(npm, tokenId);
        if (amount0 != 0) refund(pos.token0, owner, amount0);
        if (amount1 != 0) refund(pos.token1, owner, amount1);
    }

    /// @dev Decrease liquidity and swap the tokens to a single token
    function _decreaseCollectSingle(
        INPM.DecreaseLiquidityParams memory params,
        Position memory pos,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData
    ) private returns (uint256 amount) {
        uint256 amountMin;
        // Slippage check is done here instead of `NonfungiblePositionManager`
        if (zeroForOne) {
            amountMin = params.amount1Min;
            params.amount1Min = 0;
        } else {
            amountMin = params.amount0Min;
            params.amount0Min = 0;
        }
        // Reuse the `amount0Min` and `amount1Min` fields to avoid stack too deep error
        (params.amount0Min, params.amount1Min) = NPMCaller.decreaseLiquidity(npm, params);
        uint256 tokenId = params.tokenId;
        // Collect the tokens owed and deduct transaction fees
        (uint256 amount0, uint256 amount1) = _collectMinusFees(
            pos,
            tokenId,
            params.amount0Min,
            params.amount1Min,
            params.liquidity,
            feePips
        );
        // Swap to the desired token and send it to the position owner
        // It is assumed that the swap is `exactIn` and all of the input tokens are consumed.
        unchecked {
            if (zeroForOne) {
                amount = amount1 + _swap(castPoolKey(pos), amount0, true, swapData);
                refund(pos.token1, NPMCaller.ownerOf(npm, tokenId), amount);
            } else {
                amount = amount0 + _swap(castPoolKey(pos), amount1, false, swapData);
                refund(pos.token0, NPMCaller.ownerOf(npm, tokenId), amount);
            }
        }
        if (amount < amountMin) revert InsufficientAmount();
    }

    /// @dev Internal decrease liquidity abstraction
    function _decreaseLiquiditySingle(
        INPM.DecreaseLiquidityParams memory params,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData
    ) private returns (uint256 amount) {
        Position memory pos = _positions(params.tokenId);
        amount = _decreaseCollectSingle(params, pos, zeroForOne, feePips, swapData);
    }

    /// @dev Internal function to remove liquidity and collect tokens to this contract minus fees
    function _removeAndCollect(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips
    ) private returns (address token0, address token1, uint256 amount0, uint256 amount1) {
        uint256 tokenId = params.tokenId;
        Position memory pos = _positions(tokenId);
        token0 = pos.token0;
        token1 = pos.token1;
        // Update `params.liquidity` to the current liquidity
        params.liquidity = pos.liquidity;
        (uint256 amount0Principal, uint256 amount1Principal) = NPMCaller.decreaseLiquidity(npm, params);
        // Collect the tokens owed and deduct transaction fees
        (amount0, amount1) = _collectMinusFees(tokenId, token0, token1, amount0Principal, amount1Principal, feePips);
    }

    /// @dev Internal remove liquidity abstraction
    function _removeLiquidity(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips
    ) private returns (uint256, uint256) {
        uint256 tokenId = params.tokenId;
        (address token0, address token1, uint256 amount0, uint256 amount1) = _removeAndCollect(params, feePips);
        address owner = NPMCaller.ownerOf(npm, tokenId);
        if (amount0 != 0) refund(token0, owner, amount0);
        if (amount1 != 0) refund(token1, owner, amount1);
        _burn(tokenId);
        return (amount0, amount1);
    }

    /// @dev Internal function to remove liquidity and swap to a single token
    function _removeLiquiditySingle(
        INPM.DecreaseLiquidityParams memory params,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData
    ) private returns (uint256 amount) {
        uint256 tokenId = params.tokenId;
        Position memory pos = _positions(tokenId);
        // Update `params.liquidity` to the current liquidity
        params.liquidity = pos.liquidity;
        amount = _decreaseCollectSingle(params, pos, zeroForOne, feePips, swapData);
        _burn(tokenId);
    }

    /// @dev Internal reinvest abstraction
    function _reinvest(
        INPM.IncreaseLiquidityParams memory params,
        uint256 feePips,
        bytes calldata swapData
    ) private returns (uint128, uint256, uint256) {
        Position memory pos = _positions(params.tokenId);
        PoolKey memory poolKey = castPoolKey(pos);
        uint256 amount0;
        uint256 amount1;
        {
            // Calculate the principal amounts
            (uint160 sqrtPriceX96, ) = V3PoolCallee
                .wrap(PoolAddress.computeAddressSorted(factory, poolKey))
                .sqrtPriceX96AndTick();
            (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                pos.tickLower.getSqrtRatioAtTick(),
                pos.tickUpper.getSqrtRatioAtTick(),
                pos.liquidity
            );
        }
        // Collect the tokens owed then deduct transaction fees
        (amount0, amount1) = _collectMinusFees(params.tokenId, pos.token0, pos.token1, amount0, amount1, feePips);
        // Perform optimal swap and update `params`
        (params.amount0Desired, params.amount1Desired) = _optimalSwap(
            poolKey,
            pos.tickLower,
            pos.tickUpper,
            amount0,
            amount1,
            swapData
        );
        return _increaseLiquidity(params, pos.token0, pos.token1);
    }

    /// @dev Internal rebalance abstraction
    function _rebalance(
        INPM.MintParams memory params,
        uint256 tokenId,
        uint256 feePips,
        bytes calldata swapData
    ) private returns (uint256 newTokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        // Remove liquidity and collect the tokens owed
        (, , amount0, amount1) = _removeAndCollect(
            INPM.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: 0, // Updated in `_removeAndCollect`
                amount0Min: 0,
                amount1Min: 0,
                deadline: params.deadline
            }),
            feePips
        );
        // Update `recipient` to the current owner
        params.recipient = NPMCaller.ownerOf(npm, tokenId);
        // Perform optimal swap
        (params.amount0Desired, params.amount1Desired) = _optimalSwap(
            castPoolKey(params),
            params.tickLower,
            params.tickUpper,
            amount0,
            amount1,
            swapData
        );
        // `token0` and `token1` are assumed to be the same as the old position while fee tier may change.
        (newTokenId, liquidity, amount0, amount1) = _mint(params);
    }

    /// @notice Approve of a specific token ID for spending by this contract via signature if necessary
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v The recovery byte of the signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    function selfPermitIfNecessary(uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) internal {
        if (
            !(NPMCaller.getApproved(npm, tokenId) == address(this) ||
                NPMCaller.isApprovedForAll(npm, NPMCaller.ownerOf(npm, tokenId), address(this)))
        ) NPMCaller.permit(npm, address(this), tokenId, deadline, v, r, s);
    }

    /************************************************
     *  LIQUIDITY MANAGEMENT
     ***********************************************/

    /// @inheritdoc IUniV3Automan
    function mint(
        INPM.MintParams memory params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        pullAndApprove(params.token0, params.token1, params.amount0Desired, params.amount1Desired);
        (tokenId, liquidity, amount0, amount1) = _mint(params);
        emit Mint(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function mintOptimal(
        INPM.MintParams memory params,
        bytes calldata swapData
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        PoolKey memory poolKey = castPoolKey(params);
        uint256 amount0Desired = params.amount0Desired;
        uint256 amount1Desired = params.amount1Desired;
        // Pull tokens
        if (amount0Desired != 0) pay(poolKey.token0, msg.sender, address(this), amount0Desired);
        if (amount1Desired != 0) pay(poolKey.token1, msg.sender, address(this), amount1Desired);
        // Perform optimal swap after which the amounts desired are updated
        (params.amount0Desired, params.amount1Desired) = _optimalSwap(
            poolKey,
            params.tickLower,
            params.tickUpper,
            amount0Desired,
            amount1Desired,
            swapData
        );
        (tokenId, liquidity, amount0, amount1) = _mint(params);
        emit Mint(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function increaseLiquidity(
        INPM.IncreaseLiquidityParams memory params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        uint256 tokenId = params.tokenId;
        Position memory pos = _positions(tokenId);
        address token0 = pos.token0;
        address token1 = pos.token1;
        pullAndApprove(token0, token1, params.amount0Desired, params.amount1Desired);
        (liquidity, amount0, amount1) = _increaseLiquidity(params, token0, token1);
        emit IncreaseLiquidity(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function increaseLiquidityOptimal(
        INPM.IncreaseLiquidityParams memory params,
        bytes calldata swapData
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        Position memory pos = _positions(params.tokenId);
        address token0 = pos.token0;
        address token1 = pos.token1;
        uint256 amount0Desired = params.amount0Desired;
        uint256 amount1Desired = params.amount1Desired;
        // Pull tokens
        if (amount0Desired != 0) pay(token0, msg.sender, address(this), amount0Desired);
        if (amount1Desired != 0) pay(token1, msg.sender, address(this), amount1Desired);
        // Perform optimal swap after which the amounts desired are updated
        (params.amount0Desired, params.amount1Desired) = _optimalSwap(
            castPoolKey(pos),
            pos.tickLower,
            pos.tickUpper,
            amount0Desired,
            amount1Desired,
            swapData
        );
        (liquidity, amount0, amount1) = _increaseLiquidity(params, token0, token1);
        emit IncreaseLiquidity(params.tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function decreaseLiquidity(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips
    ) external returns (uint256 amount0, uint256 amount1) {
        checkFeeSanity(feePips);
        uint256 tokenId = params.tokenId;
        checkAuthorizedForToken(tokenId);
        (amount0, amount1) = _decreaseLiquidity(params, feePips);
        emit DecreaseLiquidity(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function decreaseLiquidity(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount0, uint256 amount1) {
        checkFeeSanity(feePips);
        uint256 tokenId = params.tokenId;
        checkAuthorizedForToken(tokenId);
        selfPermitIfNecessary(tokenId, permitDeadline, v, r, s);
        (amount0, amount1) = _decreaseLiquidity(params, feePips);
        emit DecreaseLiquidity(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function decreaseLiquiditySingle(
        INPM.DecreaseLiquidityParams memory params,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData
    ) external returns (uint256 amount) {
        checkFeeSanity(feePips);
        uint256 tokenId = params.tokenId;
        checkAuthorizedForToken(tokenId);
        amount = _decreaseLiquiditySingle(params, zeroForOne, feePips, swapData);
        emit DecreaseLiquidity(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function decreaseLiquiditySingle(
        INPM.DecreaseLiquidityParams memory params,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount) {
        checkFeeSanity(feePips);
        uint256 tokenId = params.tokenId;
        checkAuthorizedForToken(tokenId);
        selfPermitIfNecessary(tokenId, permitDeadline, v, r, s);
        amount = _decreaseLiquiditySingle(params, zeroForOne, feePips, swapData);
        emit DecreaseLiquidity(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function removeLiquidity(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips
    ) external returns (uint256 amount0, uint256 amount1) {
        checkFeeSanity(feePips);
        uint256 tokenId = params.tokenId;
        checkAuthorizedForToken(tokenId);
        (amount0, amount1) = _removeLiquidity(params, feePips);
        emit RemoveLiquidity(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function removeLiquidity(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount0, uint256 amount1) {
        checkFeeSanity(feePips);
        uint256 tokenId = params.tokenId;
        checkAuthorizedForToken(tokenId);
        selfPermitIfNecessary(tokenId, permitDeadline, v, r, s);
        (amount0, amount1) = _removeLiquidity(params, feePips);
        emit RemoveLiquidity(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function removeLiquiditySingle(
        INPM.DecreaseLiquidityParams memory params,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData
    ) external returns (uint256 amount) {
        checkFeeSanity(feePips);
        uint256 tokenId = params.tokenId;
        checkAuthorizedForToken(tokenId);
        amount = _removeLiquiditySingle(params, zeroForOne, feePips, swapData);
        emit RemoveLiquidity(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function removeLiquiditySingle(
        INPM.DecreaseLiquidityParams memory params,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount) {
        checkFeeSanity(feePips);
        uint256 tokenId = params.tokenId;
        checkAuthorizedForToken(tokenId);
        selfPermitIfNecessary(tokenId, permitDeadline, v, r, s);
        amount = _removeLiquiditySingle(params, zeroForOne, feePips, swapData);
        emit RemoveLiquidity(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function reinvest(
        INPM.IncreaseLiquidityParams memory params,
        uint256 feePips,
        bytes calldata swapData
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        checkFeeSanity(feePips);
        uint256 tokenId = params.tokenId;
        checkAuthorizedForToken(tokenId);
        (liquidity, amount0, amount1) = _reinvest(params, feePips, swapData);
        emit Reinvest(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function reinvest(
        INPM.IncreaseLiquidityParams memory params,
        uint256 feePips,
        bytes calldata swapData,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        checkFeeSanity(feePips);
        uint256 tokenId = params.tokenId;
        checkAuthorizedForToken(tokenId);
        selfPermitIfNecessary(tokenId, permitDeadline, v, r, s);
        (liquidity, amount0, amount1) = _reinvest(params, feePips, swapData);
        emit Reinvest(tokenId);
    }

    /// @inheritdoc IUniV3Automan
    function rebalance(
        INPM.MintParams memory params,
        uint256 tokenId,
        uint256 feePips,
        bytes calldata swapData
    ) external returns (uint256 newTokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        checkFeeSanity(feePips);
        checkAuthorizedForToken(tokenId);
        (newTokenId, liquidity, amount0, amount1) = _rebalance(params, tokenId, feePips, swapData);
        emit Rebalance(newTokenId);
    }

    /// @inheritdoc IUniV3Automan
    function rebalance(
        INPM.MintParams memory params,
        uint256 tokenId,
        uint256 feePips,
        bytes calldata swapData,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 newTokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        checkFeeSanity(feePips);
        checkAuthorizedForToken(tokenId);
        selfPermitIfNecessary(tokenId, permitDeadline, v, r, s);
        (newTokenId, liquidity, amount0, amount1) = _rebalance(params, tokenId, feePips, swapData);
        emit Rebalance(newTokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for gas griefing protection.
/// - For ERC20s, this implementation won't check that a token has code,
/// responsibility is delegated to the caller.
library SafeTransferLib {
    /*                       CUSTOM ERRORS                        */

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*                         CONSTANTS                          */

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*                       ETH OPERATIONS                       */

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    ///
    /// Note: This implementation does NOT protect against gas griefing.
    /// Please use `forceSafeTransferETH` for gas griefing protection.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overridden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*                      ERC20 OPERATIONS                      */

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` argument is already written to the memory word at 0x60.
            amount := mload(0x60)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x34.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {IPoolInitializer} from "@uniswap/v3-periphery/contracts/interfaces/IPoolInitializer.sol";
import {IERC721Permit} from "@uniswap/v3-periphery/contracts/interfaces/IERC721Permit.sol";
import {IPeripheryPayments} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";
import {IPeripheryImmutableState} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
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
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
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
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "./FullMath.sol";
import "./TernaryLib.sol";
import "./UnsafeMath.sol";

/// @title Liquidity amount functions
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-periphery/blob/main/contracts/libraries/LiquidityAmounts.sol)
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    using UnsafeMath for *;

    error OverflowUint128();

    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        if ((y = uint128(x)) != x) revert OverflowUint128();
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2(sqrtRatioAX96, sqrtRatioBX96);
        uint256 intermediate = FullMath.mulDiv96(sqrtRatioAX96, sqrtRatioBX96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96.sub(sqrtRatioAX96)));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2(sqrtRatioAX96, sqrtRatioBX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96.sub(sqrtRatioAX96)));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2(sqrtRatioAX96, sqrtRatioBX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);
            // liquidity = min(liquidity0, liquidity1);
            assembly {
                liquidity := xor(liquidity0, mul(xor(liquidity0, liquidity1), lt(liquidity1, liquidity0)))
            }
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2(sqrtRatioAX96, sqrtRatioBX96);
        return
            FullMath
                .mulDiv(uint256(liquidity) << FixedPoint96.RESOLUTION, sqrtRatioBX96.sub(sqrtRatioAX96), sqrtRatioBX96)
                .div(sqrtRatioAX96);
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2(sqrtRatioAX96, sqrtRatioBX96);
        return FullMath.mulDiv96(liquidity, sqrtRatioBX96.sub(sqrtRatioAX96));
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2(sqrtRatioAX96, sqrtRatioBX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INonfungiblePositionManager as INPM, IERC721Enumerable, IERC721Permit} from "./interfaces/INonfungiblePositionManager.sol";

// details about the uniswap position
struct PositionFull {
    // the nonce for permits
    uint96 nonce;
    // the address that is approved for spending this token
    address operator;
    address token0;
    address token1;
    // The pool's fee in hundredths of a bip, i.e. 1e-6
    uint24 fee;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
    // the fee growth of the aggregate position as of the last action on the individual position
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    // how many uncollected tokens are owed to the position, as of the last computation
    uint128 tokensOwed0;
    uint128 tokensOwed1;
}

struct Position {
    address token0;
    address token1;
    // The pool's fee in hundredths of a bip, i.e. 1e-6
    uint24 fee;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
}

/// @title Uniswap v3 Nonfungible Position Manager Caller
/// @author Aperture Finance
/// @notice Gas efficient library to call `INonfungiblePositionManager` assuming it exists.
/// @dev Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// However, this is safe because "Note that you do not need to update the free memory pointer if there is no following
/// allocation, but you can only use memory starting from the current offset given by the free memory pointer."
/// according to https://docs.soliditylang.org/en/latest/assembly.html#memory-safety.
/// When bubbling up the revert reason, it is safe to overwrite the free memory pointer 0x40 and the zero pointer 0x60
/// before exiting because a contract obtains a freshly cleared instance of memory for each message call.
library NPMCaller {
    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    /// function throws for queries about the zero address.
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param owner An address for whom to query the balance
    /// @return amount The number of NFTs owned by `owner`, possibly zero
    function balanceOf(INPM npm, address owner) internal view returns (uint256 amount) {
        bytes4 selector = IERC721.balanceOf.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, owner)
            // We use 36 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), npm, 0, 0x24, 0, 0x20)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            amount := mload(0)
        }
    }

    /// @dev Returns the total amount of tokens stored by the contract.
    function totalSupply(INPM npm) internal view returns (uint256 amount) {
        bytes4 selector = IERC721Enumerable.totalSupply.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            // `totalSupply` should never revert according to the ERC721 standard.
            amount := mload(iszero(staticcall(gas(), npm, 0, 4, 0, 0x20)))
        }
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The identifier for an NFT
    /// @return owner The address of the owner of the NFT
    function ownerOf(INPM npm, uint256 tokenId) internal view returns (address owner) {
        bytes4 selector = IERC721.ownerOf.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, tokenId)
            // We use 36 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), npm, 0, 0x24, 0, 0x20)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            owner := mload(0)
        }
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `tokenId` is not a valid NFT.
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The NFT to find the approved address for
    /// @return operator The approved address for this NFT, or the zero address if there is none
    function getApproved(INPM npm, uint256 tokenId) internal view returns (address operator) {
        bytes4 selector = IERC721.getApproved.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, tokenId)
            // We use 36 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), npm, 0, 0x24, 0, 0x20)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            operator := mload(0)
        }
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// Throws unless `msg.sender` is the current NFT owner, or an authorized
    /// operator of the current owner.
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param spender The new approved NFT controller
    /// @param tokenId The NFT to approve
    function approve(INPM npm, address spender, uint256 tokenId) internal {
        bytes4 selector = IERC721.approve.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, spender)
            mstore(0x24, tokenId)
            // We use 68 because of the length of our calldata.
            if iszero(call(gas(), npm, 0, 0, 0x44, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Clear first 4 bytes of the free memory pointer.
            mstore(0x24, 0)
        }
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param owner The address that owns the NFTs
    /// @param operator The address that acts on behalf of the owner
    /// @return isApproved True if `operator` is an approved operator for `owner`, false otherwise
    function isApprovedForAll(INPM npm, address owner, address operator) internal view returns (bool isApproved) {
        bytes4 selector = IERC721.isApprovedForAll.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, owner)
            mstore(0x24, operator)
            // We use 68 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            // `isApprovedForAll` should never revert according to the ERC721 standard.
            isApproved := mload(iszero(staticcall(gas(), npm, 0, 0x44, 0, 0x20)))
            // Clear first 4 bytes of the free memory pointer.
            mstore(0x24, 0)
        }
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    /// all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    /// multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(INPM npm, address operator, bool approved) internal {
        bytes4 selector = IERC721.setApprovalForAll.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, operator)
            mstore(0x24, approved)
            // We use 68 because of the length of our calldata.
            if iszero(call(gas(), npm, 0, 0, 0x44, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Clear first 4 bytes of the free memory pointer.
            mstore(0x24, 0)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.positions(tokenId)`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The ID of the token that represents the position
    function positionsFull(INPM npm, uint256 tokenId) internal view returns (PositionFull memory pos) {
        bytes4 selector = INPM.positions.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, tokenId)
            // We use 36 because of the length of our calldata.
            // We copy up to 384 bytes of return data at pos's pointer.
            if iszero(staticcall(gas(), npm, 0, 0x24, pos, 0x180)) {
                // Bubble up the revert reason.
                revert(pos, returndatasize())
            }
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.positions(tokenId)`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The ID of the token that represents the position
    function positions(INPM npm, uint256 tokenId) internal view returns (Position memory pos) {
        bytes4 selector = INPM.positions.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, tokenId)
            // We use 36 because of the length of our calldata.
            // We copy up to 256 bytes of return data at `pos` which is the free memory pointer.
            if iszero(staticcall(gas(), npm, 0, 0x24, pos, 0x100)) {
                // Bubble up the revert reason.
                revert(pos, returndatasize())
            }
            // Move the free memory pointer to the end of the struct.
            mstore(0x40, add(pos, 0x100))
            // Skip the first two struct members.
            pos := add(pos, 0x40)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.mint`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param params The parameters for minting a position
    function mint(
        INPM npm,
        INPM.MintParams memory params
    ) internal returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        uint32 selector = uint32(INPM.mint.selector);
        assembly ("memory-safe") {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // Cache the memory word before `params`.
            let memBeforeParams := sub(params, 0x20)
            let wordBeforeParams := mload(memBeforeParams)
            // Write the function selector 4 bytes before `params`.
            mstore(memBeforeParams, selector)
            // We use 356 because of the length of our calldata.
            // We copy up to 128 bytes of return data at the free memory pointer.
            if iszero(call(gas(), npm, 0, sub(params, 4), 0x164, 0, 0x80)) {
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Read the return data.
            tokenId := mload(0)
            liquidity := mload(0x20)
            amount0 := mload(0x40)
            amount1 := mload(0x60)
            // Restore the free memory pointer, zero pointer and memory word before `params`.
            // `memBeforeParams` >= 0x60 so restore it after `mload`.
            mstore(memBeforeParams, wordBeforeParams)
            mstore(0x40, fmp)
            mstore(0x60, 0)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.increaseLiquidity`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param params The parameters for increasing liquidity in a position
    function increaseLiquidity(
        INPM npm,
        INPM.IncreaseLiquidityParams memory params
    ) internal returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        uint32 selector = uint32(INPM.increaseLiquidity.selector);
        assembly ("memory-safe") {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // Cache the memory word before `params`.
            let memBeforeParams := sub(params, 0x20)
            let wordBeforeParams := mload(memBeforeParams)
            // Write the function selector 4 bytes before `params`.
            mstore(memBeforeParams, selector)
            // We use 196 because of the length of our calldata.
            // We copy up to 96 bytes of return data at the free memory pointer.
            if iszero(call(gas(), npm, 0, sub(params, 4), 0xc4, 0, 0x60)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Restore the memory word before `params`.
            mstore(memBeforeParams, wordBeforeParams)
            // Read the return data.
            liquidity := mload(0)
            amount0 := mload(0x20)
            amount1 := mload(0x40)
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.decreaseLiquidity`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param params The parameters for decreasing liquidity in a position
    function decreaseLiquidity(
        INPM npm,
        INPM.DecreaseLiquidityParams memory params
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint32 selector = uint32(INPM.decreaseLiquidity.selector);
        assembly ("memory-safe") {
            // Cache the memory word before `params`.
            let memBeforeParams := sub(params, 0x20)
            let wordBeforeParams := mload(memBeforeParams)
            // Write the function selector 4 bytes before `params`.
            mstore(memBeforeParams, selector)
            // We use 164 because of the length of our calldata.
            // We use 0 and 64 to copy up to 64 bytes of return data into the scratch space.
            if iszero(call(gas(), npm, 0, sub(params, 4), 0xa4, 0, 0x40)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Restore the memory word before `params`.
            mstore(memBeforeParams, wordBeforeParams)
            // Read the return data.
            amount0 := mload(0)
            amount1 := mload(0x20)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.burn`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The token ID of the position to burn
    function burn(INPM npm, uint256 tokenId) internal {
        bytes4 selector = INPM.burn.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, tokenId)
            // We use 36 because of the length of our calldata.
            if iszero(call(gas(), npm, 0, 0, 0x24, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.collect`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The token ID of the position to collect fees for
    /// @param recipient The address that receives the fees
    function collect(INPM npm, uint256 tokenId, address recipient) internal returns (uint256 amount0, uint256 amount1) {
        bytes4 selector = INPM.collect.selector;
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 4), tokenId)
            mstore(add(fmp, 0x24), recipient)
            // amount0Max = amount1Max = type(uint128).max
            mstore(add(fmp, 0x44), 0xffffffffffffffffffffffffffffffff)
            mstore(add(fmp, 0x64), 0xffffffffffffffffffffffffffffffff)
            // We use 132 because of the length of our calldata.
            // We use 0 and 64 to copy up to 64 bytes of return data into the scratch space.
            if iszero(call(gas(), npm, 0, fmp, 0x84, 0, 0x40)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            amount0 := mload(0)
            amount1 := mload(0x20)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.permit`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        INPM npm,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        bytes4 selector = IERC721Permit.permit.selector;
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 4), spender)
            mstore(add(fmp, 0x24), tokenId)
            mstore(add(fmp, 0x44), deadline)
            mstore(add(fmp, 0x64), v)
            mstore(add(fmp, 0x84), r)
            mstore(add(fmp, 0xa4), s)
            // We use 196 because of the length of our calldata.
            if iszero(call(gas(), npm, 0, fmp, 0xc4, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./TernaryLib.sol";

/// @notice The identifying key of the pool
struct PoolKey {
    address token0;
    address token1;
    uint24 fee;
}

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-periphery/blob/main/contracts/libraries/PoolAddress.sol)
/// @dev Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// However, this is safe because "Note that you do not need to update the free memory pointer if there is no following
/// allocation, but you can only use memory starting from the current offset given by the free memory pointer."
/// according to https://docs.soliditylang.org/en/latest/assembly.html#memory-safety.
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return key The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (PoolKey memory key) {
        (tokenA, tokenB) = TernaryLib.sort2(tokenA, tokenB);
        /// @solidity memory-safe-assembly
        assembly {
            // Must inline this for best performance
            mstore(key, tokenA)
            mstore(add(key, 0x20), tokenB)
            mstore(add(key, 0x40), fee)
        }
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param token0 The first token of a pool, already sorted
    /// @param token1 The second token of a pool, already sorted
    /// @param fee The fee level of the pool
    /// @return key The pool details with ordered token0 and token1 assignments
    function getPoolKeySorted(address token0, address token1, uint24 fee) internal pure returns (PoolKey memory key) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(key, token0)
            mstore(add(key, 0x20), token1)
            mstore(add(key, 0x40), fee)
        }
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        return computeAddressSorted(factory, key);
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @dev Assumes PoolKey is sorted
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddressSorted(address factory, PoolKey memory key) internal pure returns (address pool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // abi.encodePacked(hex'ff', factory, poolHash, POOL_INIT_CODE_HASH)
            // Prefix the factory address with 0xff.
            mstore(0, or(factory, 0xff0000000000000000000000000000000000000000))
            mstore(0x20, keccak256(key, 0x60))
            mstore(0x40, POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(keccak256(0x0b, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }

    /// @notice Deterministically computes the pool address given the factory, tokens, and the fee
    /// @param factory The Uniswap V3 factory contract address
    /// @param tokenA One of the tokens in the pool, unsorted
    /// @param tokenB The other token in the pool, unsorted
    /// @param fee The fee tier of the pool
    function computeAddress(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        (tokenA, tokenB) = TernaryLib.sort2(tokenA, tokenB);
        return computeAddressSorted(factory, tokenA, tokenB, fee);
    }

    /// @notice Deterministically computes the pool address given the factory, tokens, and the fee
    /// @dev Assumes tokens are sorted
    /// @param factory The Uniswap V3 factory contract address
    /// @param tokenA One of the tokens in the pool, unsorted
    /// @param tokenB The other token in the pool, unsorted
    /// @param fee The fee tier of the pool
    function computeAddressSorted(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // Hash the pool key.
            mstore(0, tokenA)
            mstore(0x20, tokenB)
            mstore(0x40, fee)
            let poolHash := keccak256(0, 0x60)
            // abi.encodePacked(hex'ff', factory, poolHash, POOL_INIT_CODE_HASH)
            // Prefix the factory address with 0xff.
            mstore(0, or(factory, 0xff0000000000000000000000000000000000000000))
            mstore(0x20, poolHash)
            mstore(0x40, POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(keccak256(0x0b, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @dev Uses PoolKey in calldata and assumes PoolKey is sorted
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The abi encoded PoolKey of the V3 pool
    /// @return pool The contract address of the V3 pool
    function computeAddressCalldata(address factory, bytes calldata key) internal pure returns (address pool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // Hash the pool key.
            calldatacopy(0, key.offset, 0x60)
            let poolHash := keccak256(0, 0x60)
            // abi.encodePacked(hex'ff', factory, poolHash, POOL_INIT_CODE_HASH)
            // Prefix the factory address with 0xff.
            mstore(0, or(factory, 0xff0000000000000000000000000000000000000000))
            mstore(0x20, poolHash)
            mstore(0x40, POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(keccak256(0x0b, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "solady/src/utils/SafeTransferLib.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {ERC20Callee} from "../libraries/ERC20Caller.sol";
import {CallbackValidation} from "@aperture_finance/uni-v3-lib/src/CallbackValidation.sol";
import {PoolAddress, PoolKey} from "@aperture_finance/uni-v3-lib/src/PoolAddress.sol";
import {TernaryLib} from "@aperture_finance/uni-v3-lib/src/TernaryLib.sol";
import {OptimalSwap, TickMath, V3PoolCallee} from "../libraries/OptimalSwap.sol";
import {Payments, UniV3Immutables} from "./Payments.sol";

abstract contract SwapRouter is UniV3Immutables, Payments, IUniswapV3SwapCallback {
    using SafeTransferLib for address;
    using TernaryLib for bool;
    using TickMath for int24;

    /// @dev Literal numbers used in sqrtPriceLimitX96 = zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1
    /// = (MAX_SQRT_RATIO - 1) ^ ((MIN_SQRT_RATIO + 1 ^ MAX_SQRT_RATIO - 1) * zeroForOne)
    uint160 internal constant MAX_SQRT_RATIO_LESS_ONE = 1461446703485210103287273052203988822378723970342 - 1;
    /// @dev MIN_SQRT_RATIO + 1 ^ MAX_SQRT_RATIO - 1
    uint160 internal constant XOR_SQRT_RATIO =
        (4295128739 + 1) ^ (1461446703485210103287273052203988822378723970342 - 1);

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        // Only accept callbacks from an official Uniswap V3 pool
        address pool = CallbackValidation.verifyCallbackCalldata(factory, data);
        if (amount0Delta > 0) {
            address token0;
            assembly {
                token0 := calldataload(data.offset)
            }
            pay(token0, address(this), pool, uint256(amount0Delta));
        } else {
            address token1;
            assembly {
                token1 := calldataload(add(data.offset, 0x20))
            }
            pay(token1, address(this), pool, uint256(amount1Delta));
        }
    }

    /// @dev Make a direct `exactIn` pool swap
    /// @param poolKey The pool key containing the token addresses and fee tier
    /// @param pool The address of the pool
    /// @param amountIn The amount of token to be swapped
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @return amountOut The amount of token received after swap
    function _poolSwap(
        PoolKey memory poolKey,
        address pool,
        uint256 amountIn,
        bool zeroForOne
    ) internal returns (uint256 amountOut) {
        if (amountIn != 0) {
            uint256 valueBeforePoolKey;
            bytes memory data;
            assembly ("memory-safe") {
                // Equivalent to `data = abi.encode(poolKey)`
                data := sub(poolKey, 0x20)
                valueBeforePoolKey := mload(data)
                mstore(data, 0x60)
            }
            uint160 sqrtPriceLimitX96;
            // Equivalent to `sqrtPriceLimitX96 = zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1`
            assembly {
                sqrtPriceLimitX96 := xor(MAX_SQRT_RATIO_LESS_ONE, mul(XOR_SQRT_RATIO, zeroForOne))
            }
            (int256 amount0Delta, int256 amount1Delta) = V3PoolCallee.wrap(pool).swap(
                address(this),
                zeroForOne,
                int256(amountIn),
                sqrtPriceLimitX96,
                data
            );
            unchecked {
                amountOut = 0 - zeroForOne.ternary(uint256(amount1Delta), uint256(amount0Delta));
            }
            assembly ("memory-safe") {
                // Restore the memory slot before `poolKey`
                mstore(data, valueBeforePoolKey)
            }
        }
    }

    /// @dev Make an `exactIn` swap through a whitelisted external router
    /// @param poolKey The pool key containing the token addresses and fee tier
    /// @param router The address of the external router
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param swapData The address of the external router and call data, not abi-encoded
    /// @return amountOut The amount of token received after swap
    function _routerSwap(
        PoolKey memory poolKey,
        address router,
        bool zeroForOne,
        bytes calldata swapData
    ) internal returns (uint256 amountOut) {
        (address tokenIn, address tokenOut) = zeroForOne.switchIf(poolKey.token1, poolKey.token0);
        uint256 balanceBefore = ERC20Callee.wrap(tokenOut).balanceOf(address(this));
        // Approve `router` to spend `tokenIn`
        tokenIn.safeApprove(router, type(uint256).max);
        /*
            If `swapData` is encoded as `abi.encode(router, data)`, the memory layout will be:
            0x00         : 0x20         : 0x40         : 0x60         : 0x80
            total length : router       : 0x40 (offset): data length  : data
            Instead, we encode it as:
            ```
            bytes memory swapData = abi.encodePacked(router, data);
            ```
            So the memory layout will be:
            0x00         : 0x20         : 0x34
            total length : router       : data
            To decode it in memory, one can use:
            ```
            bytes memory data;
            assembly {
                router := shr(96, mload(add(swapData, 0x20)))
                data := add(swapData, 0x14)
                mstore(data, sub(mload(swapData), 0x14))
            }
            ```
            knowing that `data.length == swapData.length - 20`.
         */
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            // Strip the first 20 bytes of `swapData` which is the router address.
            let calldataLength := sub(swapData.length, 20)
            calldatacopy(fmp, add(swapData.offset, 20), calldataLength)
            // Ignore the return data unless an error occurs
            if iszero(call(gas(), router, 0, fmp, calldataLength, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
        }
        // Reset approval
        tokenIn.safeApprove(router, 0);
        uint256 balanceAfter = ERC20Callee.wrap(tokenOut).balanceOf(address(this));
        amountOut = balanceAfter - balanceBefore;
    }

    /// @dev Swap tokens to the optimal ratio to add liquidity in the same pool
    /// @param poolKey The pool key containing the token addresses and fee tier
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount0Desired The desired amount of token0 to be spent
    /// @param amount1Desired The desired amount of token1 to be spent
    /// @return amount0 The amount of token0 after swap
    /// @return amount1 The amount of token1 after swap
    function _optimalSwapWithPool(
        PoolKey memory poolKey,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) internal returns (uint256 amount0, uint256 amount1) {
        address pool = PoolAddress.computeAddressSorted(factory, poolKey);
        (uint256 amountIn, , bool zeroForOne, ) = OptimalSwap.getOptimalSwap(
            V3PoolCallee.wrap(pool),
            tickLower,
            tickUpper,
            amount0Desired,
            amount1Desired
        );
        uint256 amountOut = _poolSwap(poolKey, pool, amountIn, zeroForOne);
        unchecked {
            // amount0 = amount0Desired + zeroForOne ? - amountIn : amountOut
            // amount1 = amount1Desired + zeroForOne ? amountOut : - amountIn
            (amount0, amount1) = zeroForOne.switchIf(amountOut, 0 - amountIn);
            amount0 += amount0Desired;
            amount1 += amount1Desired;
        }
    }

    /// @dev Swap tokens to the optimal ratio to add liquidity with an external router
    /// @param poolKey The pool key containing the token addresses and fee tier
    /// @param router The address of the external router
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount0Desired The desired amount of token0 to be spent
    /// @param amount1Desired The desired amount of token1 to be spent
    /// @return amount0 The amount of token0 after swap
    /// @return amount1 The amount of token1 after swap
    function _optimalSwapWithRouter(
        PoolKey memory poolKey,
        address router,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired,
        bytes calldata swapData
    ) internal returns (uint256 amount0, uint256 amount1) {
        (uint160 sqrtPriceX96, ) = V3PoolCallee
            .wrap(PoolAddress.computeAddressSorted(factory, poolKey))
            .sqrtPriceX96AndTick();
        bool zeroForOne = OptimalSwap.isZeroForOne(
            amount0Desired,
            amount1Desired,
            sqrtPriceX96,
            tickLower.getSqrtRatioAtTick(),
            tickUpper.getSqrtRatioAtTick()
        );
        _routerSwap(poolKey, router, zeroForOne, swapData);
        amount0 = ERC20Callee.wrap(poolKey.token0).balanceOf(address(this));
        amount1 = ERC20Callee.wrap(poolKey.token1).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {INonfungiblePositionManager as INPM} from "@aperture_finance/uni-v3-lib/src/interfaces/INonfungiblePositionManager.sol";
import {V3PoolCallee} from "@aperture_finance/uni-v3-lib/src/PoolCaller.sol";
import {IUniV3Immutables} from "./IUniV3Immutables.sol";

/// @title Interface for the Uniswap v3 Automation Manager
interface IUniV3Automan is IUniV3Immutables, IUniswapV3SwapCallback {
    /************************************************
     *  EVENTS
     ***********************************************/

    event FeeConfigSet(address feeCollector, uint96 feeLimitPips);
    event ControllersSet(address[] controllers, bool[] statuses);
    event SwapRoutersSet(address[] routers, bool[] statuses);
    event Mint(uint256 indexed tokenId);
    event IncreaseLiquidity(uint256 indexed tokenId);
    event DecreaseLiquidity(uint256 indexed tokenId);
    event RemoveLiquidity(uint256 indexed tokenId);
    event Reinvest(uint256 indexed tokenId);
    event Rebalance(uint256 indexed tokenId);

    /************************************************
     *  ERRORS
     ***********************************************/

    error NotApproved();
    error InvalidSwapRouter();
    error NotWhitelistedRouter();
    error InsufficientAmount();
    error FeeLimitExceeded();

    /// @notice Get swap amount, output amount, swap direction for double-sided optimal deposit
    /// @param pool Uniswap v3 pool
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount0Desired The desired amount of token0 to be spent
    /// @param amount1Desired The desired amount of token1 to be spent
    /// @return amountIn The optimal swap amount
    /// @return amountOut Expected output amount
    /// @return zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @return sqrtPriceX96 The sqrt(price) after the swap
    function getOptimalSwap(
        V3PoolCallee pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256 amountIn, uint256 amountOut, bool zeroForOne, uint160 sqrtPriceX96);

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// token0 The address of the token0 for a specific pool
    /// token1 The address of the token1 for a specific pool
    /// fee The fee associated with the pool
    /// tickLower The lower tick of the position in which to add liquidity
    /// tickUpper The upper tick of the position in which to add liquidity
    /// amount0Desired The desired amount of token0 to be spent
    /// amount1Desired The desired amount of token1 to be spent
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check
    /// recipient The recipient of the minted position
    /// deadline The time by which the transaction must be included to effect the change
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0 spent
    /// @return amount1 The amount of token1 spent
    function mint(
        INPM.MintParams memory params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Creates a new position wrapped in a NFT using optimal swap
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// token0 The address of the token0 for a specific pool
    /// token1 The address of the token1 for a specific pool
    /// fee The fee associated with the pool
    /// tickLower The lower tick of the position in which to add liquidity
    /// tickUpper The upper tick of the position in which to add liquidity
    /// amount0Desired The desired amount of token0 to be spent
    /// amount1Desired The desired amount of token1 to be spent
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check
    /// recipient The recipient of the minted position
    /// deadline The time by which the transaction must be included to effect the change
    /// @param swapData The address of the external router and call data
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0 spent
    /// @return amount1 The amount of token1 spent
    function mintOptimal(
        INPM.MintParams memory params,
        bytes calldata swapData
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @dev Anyone can increase the liquidity of a position, but the caller must pay the tokens
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to achieve resulting liquidity
    /// @return amount1 The amount of token1 to achieve resulting liquidity
    function increaseLiquidity(
        INPM.IncreaseLiquidityParams memory params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Increases the amount of liquidity in a position using optimal swap
    /// @dev Anyone can increase the liquidity of a position, but the caller must pay the tokens
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param swapData The address of the external router and call data
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to achieve resulting liquidity
    /// @return amount1 The amount of token1 to achieve resulting liquidity
    function increaseLiquidityOptimal(
        INPM.IncreaseLiquidityParams memory params,
        bytes calldata swapData
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @dev Slippage check is delegated to `NonfungiblePositionManager` via `DecreaseLiquidityParams`.
    /// It is applied on the principal amounts excluding trading fees.
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// liquidity The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param feePips The fee in pips to be collected
    /// @return amount0 The amount of token0 returned minus fees
    /// @return amount1 The amount of token1 returned minus fees
    function decreaseLiquidity(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position using permit
    /// @dev Slippage check is delegated to `NonfungiblePositionManager` via `DecreaseLiquidityParams`.
    /// It is applied on the principal amounts excluding trading fees.
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// liquidity The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param feePips The fee in pips to be collected
    /// @param permitDeadline The deadline of the permit signature
    /// @param v The recovery byte of the signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    /// @return amount0 The amount of token0 returned minus fees
    /// @return amount1 The amount of token1 returned minus fees
    function decreaseLiquidity(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Decreases the amount of liquidity in a position and swaps to a single token
    /// @dev Slippage check is enforced by specifying `amount0Min` when `token0` is the target token
    /// and `amount1Min` otherwise, applied after transaction fees.
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// liquidity The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param zeroForOne True if token0 is being swapped for token1, false otherwise
    /// @param feePips The fee in pips to be collected
    /// @param swapData The address of the external router and call data
    /// @return amount The total amount of desired token returned minus fees
    function decreaseLiquiditySingle(
        INPM.DecreaseLiquidityParams memory params,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData
    ) external returns (uint256 amount);

    /// @notice Decreases the amount of liquidity in a position and swaps to a single token using permit
    /// @dev Slippage check is enforced by specifying `amount0Min` when `token0` is the target token
    /// and `amount1Min` otherwise, applied after transaction fees.
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// liquidity The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param zeroForOne True if token0 is being swapped for token1, false otherwise
    /// @param feePips The fee in pips to be collected
    /// @param swapData The address of the external router and call data
    /// @param permitDeadline The deadline of the permit signature
    /// @param v The recovery byte of the signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    /// @return amount The total amount of desired token returned minus fees
    function decreaseLiquiditySingle(
        INPM.DecreaseLiquidityParams memory params,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount);

    /// @notice Removes all liquidity from a position
    /// @dev Slippage check is delegated to `NonfungiblePositionManager` via `DecreaseLiquidityParams`.
    /// It is applied on the principal amounts excluding trading fees.
    /// @param params tokenId The ID of the token for which liquidity is being removed,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param feePips The fee in pips to be collected
    /// @return amount0 The amount of token0 returned minus fees
    /// @return amount1 The amount of token1 returned minus fees
    function removeLiquidity(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Removes all liquidity from a position using permit
    /// @dev Slippage check is delegated to `NonfungiblePositionManager` via `DecreaseLiquidityParams`.
    /// It is applied on the principal amounts excluding trading fees.
    /// @param params tokenId The ID of the token for which liquidity is being removed,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param feePips The fee in pips to be collected
    /// @param permitDeadline The deadline of the permit signature
    /// @param v The recovery byte of the signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    /// @return amount0 The amount of token0 returned minus fees
    /// @return amount1 The amount of token1 returned minus fees
    function removeLiquidity(
        INPM.DecreaseLiquidityParams memory params,
        uint256 feePips,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Removes all liquidity from a position and swaps to a single token
    /// @dev Slippage check is enforced by specifying `amount0Min` when `token0` is the target token
    /// and `amount1Min` otherwise, applied after transaction fees.
    /// @param params tokenId The ID of the token for which liquidity is being removed,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param zeroForOne True if token0 is being swapped for token1, false otherwise
    /// @param feePips The fee in pips to be collected
    /// @param swapData The address of the external router and call data
    /// @return amount The total amount of desired token returned minus fees
    function removeLiquiditySingle(
        INPM.DecreaseLiquidityParams memory params,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData
    ) external returns (uint256 amount);

    /// @notice Removes all liquidity from a position and swaps to a single token using permit
    /// @dev Slippage check is enforced by specifying `amount0Min` when `token0` is the target token
    /// and `amount1Min` otherwise, applied after transaction fees.
    /// @param params tokenId The ID of the token for which liquidity is being removed,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param zeroForOne True if token0 is being swapped for token1, false otherwise
    /// @param feePips The fee in pips to be collected
    /// @param swapData The address of the external router and call data
    /// @param permitDeadline The deadline of the permit signature
    /// @param v The recovery byte of the signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    /// @return amount The total amount of desired token returned minus fees
    function removeLiquiditySingle(
        INPM.DecreaseLiquidityParams memory params,
        bool zeroForOne,
        uint256 feePips,
        bytes calldata swapData,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount);

    /// @notice Reinvests all fees owed to a specific position to the same position using optimal swap
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param feePips The fee in pips to be collected
    /// @param swapData The address of the external router and call data
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to achieve resulting liquidity
    /// @return amount1 The amount of token1 to achieve resulting liquidity
    function reinvest(
        INPM.IncreaseLiquidityParams memory params,
        uint256 feePips,
        bytes calldata swapData
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Reinvests all fees owed to a specific position to the same position using optimal swap and permit
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @param feePips The fee in pips to be collected
    /// @param swapData The address of the external router and call data
    /// @param permitDeadline The deadline of the permit signature
    /// @param v The recovery byte of the signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to achieve resulting liquidity
    /// @return amount1 The amount of token1 to achieve resulting liquidity
    function reinvest(
        INPM.IncreaseLiquidityParams memory params,
        uint256 feePips,
        bytes calldata swapData,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Rebalances a position to a new tick range
    /// @param params The params of the target position after rebalance
    /// token0 The address of the token0 for a specific pool
    /// token1 The address of the token1 for a specific pool
    /// fee The fee associated with the pool
    /// tickLower The lower tick of the position in which to add liquidity
    /// tickUpper The upper tick of the position in which to add liquidity
    /// amount0Desired The desired amount of token0 to be spent
    /// amount1Desired The desired amount of token1 to be spent
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check
    /// recipient The recipient of the minted position
    /// deadline The time by which the transaction must be included to effect the change
    /// @param tokenId The ID of the position to rebalance
    /// @param feePips The fee in pips to be collected
    /// @param swapData The address of the external router and call data
    /// @return newTokenId The ID of the new position
    /// @return liquidity The amount of liquidity in the new position
    /// @return amount0 The amount of token0 in the new position
    /// @return amount1 The amount of token1 in the new position
    function rebalance(
        INPM.MintParams memory params,
        uint256 tokenId,
        uint256 feePips,
        bytes calldata swapData
    ) external returns (uint256 newTokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Rebalances a position to a new tick range using permit
    /// @param params The params of the target position after rebalance
    /// token0 The address of the token0 for a specific pool
    /// token1 The address of the token1 for a specific pool
    /// fee The fee associated with the pool
    /// tickLower The lower tick of the position in which to add liquidity
    /// tickUpper The upper tick of the position in which to add liquidity
    /// amount0Desired The desired amount of token0 to be spent
    /// amount1Desired The desired amount of token1 to be spent
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check
    /// recipient The recipient of the minted position
    /// deadline The time by which the transaction must be included to effect the change
    /// @param tokenId The ID of the position to rebalance
    /// @param feePips The fee in pips to be collected
    /// @param swapData The address of the external router and call data
    /// @param permitDeadline The deadline of the permit signature
    /// @param v The recovery byte of the signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    /// @return newTokenId The ID of the new position
    /// @return liquidity The amount of liquidity in the new position
    /// @return amount0 The amount of token0 in the new position
    /// @return amount1 The amount of token1 in the new position
    function rebalance(
        INPM.MintParams memory params,
        uint256 tokenId,
        uint256 feePips,
        bytes calldata swapData,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 newTokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.8;

import "@aperture_finance/uni-v3-lib/src/SwapMath.sol";
import "@aperture_finance/uni-v3-lib/src/TickBitmap.sol";
import "@aperture_finance/uni-v3-lib/src/TickMath.sol";

/// @title Optimal Swap Library
/// @author Aperture Finance
/// @notice Optimal library for optimal double-sided Uniswap v3 liquidity provision using closed form solution
library OptimalSwap {
    using TickMath for int24;
    using FullMath for uint256;
    using UnsafeMath for uint256;

    uint256 internal constant MAX_FEE_PIPS = 1e6;

    error Invalid_Pool();
    error Invalid_Tick_Range();
    error Math_Overflow();

    struct SwapState {
        // liquidity in range after swap, accessible by `mload(state)`
        uint128 liquidity;
        // sqrt(price) after swap, accessible by `mload(add(state, 0x20))`
        uint256 sqrtPriceX96;
        // tick after swap, accessible by `mload(add(state, 0x40))`
        int24 tick;
        // The desired amount of token0 to add liquidity, `mload(add(state, 0x60))`
        uint256 amount0Desired;
        // The desired amount of token1 to add liquidity, `mload(add(state, 0x80))`
        uint256 amount1Desired;
        // sqrt(price) at the lower tick, `mload(add(state, 0xa0))`
        uint256 sqrtRatioLowerX96;
        // sqrt(price) at the upper tick, `mload(add(state, 0xc0))`
        uint256 sqrtRatioUpperX96;
        // the fee taken from the input amount, expressed in hundredths of a bip
        // accessible by `mload(add(state, 0xe0))`
        uint256 feePips;
        // the tick spacing of the pool, accessible by `mload(add(state, 0x100))`
        int24 tickSpacing;
    }

    /// @notice Get swap amount, output amount, swap direction for double-sided optimal deposit
    /// @dev Given the elegant analytic solution and custom optimizations to Uniswap libraries,
    /// the amount of gas is at the order of 10k depending on the swap amount and the number of ticks crossed,
    /// an order of magnitude less than that achieved by binary search, which can be calculated on-chain.
    /// @param pool Uniswap v3 pool
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount0Desired The desired amount of token0 to be spent
    /// @param amount1Desired The desired amount of token1 to be spent
    /// @return amountIn The optimal swap amount
    /// @return amountOut Expected output amount
    /// @return zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @return sqrtPriceX96 The sqrt(price) after the swap
    function getOptimalSwap(
        V3PoolCallee pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) internal view returns (uint256 amountIn, uint256 amountOut, bool zeroForOne, uint160 sqrtPriceX96) {
        if (amount0Desired == 0 && amount1Desired == 0) return (0, 0, false, 0);
        if (tickLower >= tickUpper || tickLower < TickMath.MIN_TICK || tickUpper > TickMath.MAX_TICK)
            revert Invalid_Tick_Range();
        {
            // Ensure the pool exists.
            uint256 poolCodeSize;
            assembly {
                poolCodeSize := extcodesize(pool)
            }
            if (poolCodeSize == 0) revert Invalid_Pool();
        }
        // intermediate state cache
        SwapState memory state;
        // Populate `SwapState` with hardcoded offsets.
        {
            int24 tick;
            (sqrtPriceX96, tick) = pool.sqrtPriceX96AndTick();
            assembly ("memory-safe") {
                // state.tick = tick
                mstore(add(state, 0x40), tick)
            }
        }
        {
            uint128 liquidity = pool.liquidity();
            uint256 feePips = pool.fee();
            int24 tickSpacing = pool.tickSpacing();
            assembly ("memory-safe") {
                // state.liquidity = liquidity
                mstore(state, liquidity)
                // state.sqrtPriceX96 = sqrtPriceX96
                mstore(add(state, 0x20), sqrtPriceX96)
                // state.amount0Desired = amount0Desired
                mstore(add(state, 0x60), amount0Desired)
                // state.amount1Desired = amount1Desired
                mstore(add(state, 0x80), amount1Desired)
                // state.feePips = feePips
                mstore(add(state, 0xe0), feePips)
                // state.tickSpacing = tickSpacing
                mstore(add(state, 0x100), tickSpacing)
            }
        }
        uint160 sqrtRatioLowerX96 = tickLower.getSqrtRatioAtTick();
        uint160 sqrtRatioUpperX96 = tickUpper.getSqrtRatioAtTick();
        assembly ("memory-safe") {
            // state.sqrtRatioLowerX96 = sqrtRatioLowerX96
            mstore(add(state, 0xa0), sqrtRatioLowerX96)
            // state.sqrtRatioUpperX96 = sqrtRatioUpperX96
            mstore(add(state, 0xc0), sqrtRatioUpperX96)
        }
        zeroForOne = isZeroForOne(amount0Desired, amount1Desired, sqrtPriceX96, sqrtRatioLowerX96, sqrtRatioUpperX96);
        // Simulate optimal swap by crossing ticks until the direction reverses.
        crossTicks(pool, state, sqrtPriceX96, zeroForOne);
        // Active liquidity at the last tick of optimal swap
        uint128 liquidityLast;
        // sqrt(price) at the last tick of optimal swap
        uint160 sqrtPriceLastTickX96;
        // Remaining amount of token0 to add liquidity at the last tick
        uint256 amount0LastTick;
        // Remaining amount of token1 to add liquidity at the last tick
        uint256 amount1LastTick;
        assembly ("memory-safe") {
            // liquidity = state.liquidity
            liquidityLast := mload(state)
            // sqrtPriceLastTickX96 = state.sqrtPriceX96
            sqrtPriceLastTickX96 := mload(add(state, 0x20))
            // amount0LastTick = state.amount0Desired
            amount0LastTick := mload(add(state, 0x60))
            // amount1LastTick = state.amount1Desired
            amount1LastTick := mload(add(state, 0x80))
        }
        unchecked {
            if (zeroForOne) {
                // The final price is in range. Use the closed form solution.
                if (sqrtPriceLastTickX96 <= sqrtRatioUpperX96) {
                    sqrtPriceX96 = solveOptimalZeroForOne(state);
                    amountIn =
                        amount0Desired -
                        amount0LastTick +
                        (SqrtPriceMath.getAmount0Delta(sqrtPriceX96, sqrtPriceLastTickX96, liquidityLast, true) *
                            MAX_FEE_PIPS).div(MAX_FEE_PIPS - state.feePips);
                }
                // The final price is out of range. Simply consume all token0.
                else {
                    amountIn = amount0Desired;
                    sqrtPriceX96 = SqrtPriceMath.getNextSqrtPriceFromAmount0RoundingUp(
                        sqrtPriceLastTickX96,
                        liquidityLast,
                        FullMath.mulDiv(amount0LastTick, MAX_FEE_PIPS - state.feePips, MAX_FEE_PIPS),
                        true
                    );
                }
                amountOut =
                    amount1LastTick -
                    amount1Desired +
                    SqrtPriceMath.getAmount1Delta(sqrtPriceX96, sqrtPriceLastTickX96, liquidityLast, false);
            } else {
                // The final price is in range. Use the closed form solution.
                if (sqrtPriceLastTickX96 >= sqrtRatioLowerX96) {
                    sqrtPriceX96 = solveOptimalOneForZero(state);
                    amountIn =
                        amount1Desired -
                        amount1LastTick +
                        (SqrtPriceMath.getAmount1Delta(sqrtPriceLastTickX96, sqrtPriceX96, liquidityLast, true) *
                            MAX_FEE_PIPS).div(MAX_FEE_PIPS - state.feePips);
                }
                // The final price is out of range. Simply consume all token1.
                else {
                    amountIn = amount1Desired;
                    sqrtPriceX96 = SqrtPriceMath.getNextSqrtPriceFromAmount1RoundingDown(
                        sqrtPriceLastTickX96,
                        liquidityLast,
                        FullMath.mulDiv(amount1LastTick, MAX_FEE_PIPS - state.feePips, MAX_FEE_PIPS),
                        true
                    );
                }
                amountOut =
                    amount0LastTick -
                    amount0Desired +
                    SqrtPriceMath.getAmount0Delta(sqrtPriceLastTickX96, sqrtPriceX96, liquidityLast, false);
            }
        }
    }

    /// @dev Check if the remaining amount is enough to cross the next initialized tick.
    // If so, check whether the swap direction changes for optimal deposit. If so, we swap too much and the final sqrt
    // price must be between the current tick and the next tick. Otherwise the next tick must be crossed.
    function crossTicks(V3PoolCallee pool, SwapState memory state, uint160 sqrtPriceX96, bool zeroForOne) private view {
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // Ensure the initial `wordPos` doesn't coincide with the starting tick's.
        int16 wordPos = type(int16).min;
        // a word in `pool.tickBitmap`
        uint256 tickWord;

        do {
            (tickNext, wordPos, tickWord) = TickBitmap.nextInitializedTick(
                pool,
                state.tick,
                state.tickSpacing,
                zeroForOne,
                wordPos,
                tickWord
            );
            // sqrt(price) for the next tick (1/0)
            uint160 sqrtPriceNextX96 = tickNext.getSqrtRatioAtTick();
            // The desired amount of token0 to add liquidity after swap
            uint256 amount0Desired;
            // The desired amount of token1 to add liquidity after swap
            uint256 amount1Desired;

            unchecked {
                if (zeroForOne) {
                    // Abuse `amount0Desired` to store `amountIn` to avoid stack too deep errors.
                    (sqrtPriceX96, amount0Desired, amount1Desired) = SwapMath.computeSwapStepExactIn(
                        uint160(state.sqrtPriceX96),
                        sqrtPriceNextX96,
                        state.liquidity,
                        state.amount0Desired,
                        state.feePips
                    );
                    amount0Desired = state.amount0Desired - amount0Desired;
                    amount1Desired = state.amount1Desired + amount1Desired;
                } else {
                    // Abuse `amount1Desired` to store `amountIn` to avoid stack too deep errors.
                    (sqrtPriceX96, amount1Desired, amount0Desired) = SwapMath.computeSwapStepExactIn(
                        uint160(state.sqrtPriceX96),
                        sqrtPriceNextX96,
                        state.liquidity,
                        state.amount1Desired,
                        state.feePips
                    );
                    amount0Desired = state.amount0Desired + amount0Desired;
                    amount1Desired = state.amount1Desired - amount1Desired;
                }
            }

            // If the remaining amount is large enough to consume the current tick and the optimal swap direction
            // doesn't change, continue crossing ticks.
            if (sqrtPriceX96 != sqrtPriceNextX96) break;
            if (
                isZeroForOne(
                    amount0Desired,
                    amount1Desired,
                    sqrtPriceX96,
                    state.sqrtRatioLowerX96,
                    state.sqrtRatioUpperX96
                ) == zeroForOne
            ) {
                int128 liquidityNet = pool.liquidityNet(tickNext);
                assembly ("memory-safe") {
                    // If we're moving leftward, we interpret `liquidityNet` as the opposite sign.
                    // If zeroForOne, liquidityNet = -liquidityNet = ~liquidityNet + 1 = -1 ^ liquidityNet + 1.
                    // Therefore, liquidityNet = -zeroForOne ^ liquidityNet + zeroForOne.
                    liquidityNet := add(zeroForOne, xor(sub(0, zeroForOne), liquidityNet))
                    // `liquidity` is the first in `SwapState`
                    mstore(state, add(mload(state), liquidityNet))
                    // state.sqrtPriceX96 = sqrtPriceX96
                    mstore(add(state, 0x20), sqrtPriceX96)
                    // state.tick = zeroForOne ? tickNext - 1 : tickNext
                    mstore(add(state, 0x40), sub(tickNext, zeroForOne))
                    // state.amount0Desired = amount0Desired
                    mstore(add(state, 0x60), amount0Desired)
                    // state.amount1Desired = amount1Desired
                    mstore(add(state, 0x80), amount1Desired)
                }
            } else break;
        } while (true);
    }

    /// @dev Analytic solution for optimal swap between two nearest initialized ticks swapping token0 to token1
    /// @param state Pool state at the last tick of optimal swap
    /// @return sqrtPriceFinalX96 sqrt(price) after optimal swap
    function solveOptimalZeroForOne(SwapState memory state) private pure returns (uint160 sqrtPriceFinalX96) {
        /**
         * root = (sqrt(b^2 + 4ac) + b) / 2a
         * `a` is in the order of `amount0Desired`. `b` is in the order of `liquidity`.
         * `c` is in the order of `amount1Desired`.
         * `a`, `b`, `c` are signed integers in two's complement but typed as unsigned to avoid unnecessary casting.
         */
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 sqrtPriceX96;
        unchecked {
            uint256 liquidity;
            uint256 sqrtRatioLowerX96;
            uint256 sqrtRatioUpperX96;
            uint256 feePips;
            uint256 FEE_COMPLEMENT;
            assembly ("memory-safe") {
                // liquidity = state.liquidity
                liquidity := mload(state)
                // sqrtPriceX96 = state.sqrtPriceX96
                sqrtPriceX96 := mload(add(state, 0x20))
                // sqrtRatioLowerX96 = state.sqrtRatioLowerX96
                sqrtRatioLowerX96 := mload(add(state, 0xa0))
                // sqrtRatioUpperX96 = state.sqrtRatioUpperX96
                sqrtRatioUpperX96 := mload(add(state, 0xc0))
                // feePips = state.feePips
                feePips := mload(add(state, 0xe0))
                // FEE_COMPLEMENT = MAX_FEE_PIPS - feePips
                FEE_COMPLEMENT := sub(MAX_FEE_PIPS, feePips)
            }
            {
                uint256 a0;
                assembly ("memory-safe") {
                    // amount0Desired = state.amount0Desired
                    let amount0Desired := mload(add(state, 0x60))
                    let liquidityX96 := shl(96, liquidity)
                    // a = amount0Desired + liquidity / ((1 - f) * sqrtPrice) - liquidity / sqrtRatioUpper
                    a0 := add(amount0Desired, div(mul(MAX_FEE_PIPS, liquidityX96), mul(FEE_COMPLEMENT, sqrtPriceX96)))
                    a := sub(a0, div(liquidityX96, sqrtRatioUpperX96))
                    // `a` is always positive and greater than `amount0Desired`.
                    if lt(a, amount0Desired) {
                        // revert Math_Overflow()
                        mstore(0, 0x20236808)
                        revert(0x1c, 0x04)
                    }
                }
                b = a0.mulDiv96(sqrtRatioLowerX96);
                assembly {
                    b := add(div(mul(feePips, liquidity), FEE_COMPLEMENT), b)
                }
            }
            {
                // c = amount1Desired + liquidity * sqrtPrice - liquidity * sqrtRatioLower / (1 - f)
                uint256 c0 = liquidity.mulDiv96(sqrtPriceX96);
                assembly ("memory-safe") {
                    // c0 = amount1Desired + liquidity * sqrtPrice
                    c0 := add(mload(add(state, 0x80)), c0)
                }
                c = c0 - liquidity.mulDiv96((MAX_FEE_PIPS * sqrtRatioLowerX96) / FEE_COMPLEMENT);
                b -= c0.mulDiv(FixedPoint96.Q96, sqrtRatioUpperX96);
            }
            assembly {
                a := shl(1, a)
                c := shl(1, c)
            }
        }
        // Given a root exists, the following calculations cannot realistically overflow/underflow.
        unchecked {
            uint256 numerator = FullMath.sqrt(b * b + a * c) + b;
            assembly {
                // `numerator` and `a` must be positive so use `div`.
                sqrtPriceFinalX96 := div(shl(96, numerator), a)
            }
        }
        // The final price must be less than or equal to the price at the last tick.
        // However the calculated price may increase if the ratio is close to optimal.
        assembly {
            // sqrtPriceFinalX96 = min(sqrtPriceFinalX96, sqrtPriceX96)
            sqrtPriceFinalX96 := xor(
                sqrtPriceX96,
                mul(xor(sqrtPriceX96, sqrtPriceFinalX96), lt(sqrtPriceFinalX96, sqrtPriceX96))
            )
        }
    }

    /// @dev Analytic solution for optimal swap between two nearest initialized ticks swapping token1 to token0
    /// @param state Pool state at the last tick of optimal swap
    /// @return sqrtPriceFinalX96 sqrt(price) after optimal swap
    function solveOptimalOneForZero(SwapState memory state) private pure returns (uint160 sqrtPriceFinalX96) {
        /**
         * root = (sqrt(b^2 + 4ac) + b) / 2a
         * `a` is in the order of `amount0Desired`. `b` is in the order of `liquidity`.
         * `c` is in the order of `amount1Desired`.
         * `a`, `b`, `c` are signed integers in two's complement but typed as unsigned to avoid unnecessary casting.
         */
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 sqrtPriceX96;
        unchecked {
            uint256 liquidity;
            uint256 sqrtRatioLowerX96;
            uint256 sqrtRatioUpperX96;
            uint256 feePips;
            uint256 FEE_COMPLEMENT;
            assembly ("memory-safe") {
                // liquidity = state.liquidity
                liquidity := mload(state)
                // sqrtPriceX96 = state.sqrtPriceX96
                sqrtPriceX96 := mload(add(state, 0x20))
                // sqrtRatioLowerX96 = state.sqrtRatioLowerX96
                sqrtRatioLowerX96 := mload(add(state, 0xa0))
                // sqrtRatioUpperX96 = state.sqrtRatioUpperX96
                sqrtRatioUpperX96 := mload(add(state, 0xc0))
                // feePips = state.feePips
                feePips := mload(add(state, 0xe0))
                // FEE_COMPLEMENT = MAX_FEE_PIPS - feePips
                FEE_COMPLEMENT := sub(MAX_FEE_PIPS, feePips)
            }
            {
                // a = state.amount0Desired + liquidity / sqrtPrice - liquidity / ((1 - f) * sqrtRatioUpper)
                uint256 a0;
                assembly ("memory-safe") {
                    let liquidityX96 := shl(96, liquidity)
                    // a0 = state.amount0Desired + liquidity / sqrtPrice
                    a0 := add(mload(add(state, 0x60)), div(liquidityX96, sqrtPriceX96))
                    a := sub(a0, div(mul(MAX_FEE_PIPS, liquidityX96), mul(FEE_COMPLEMENT, sqrtRatioUpperX96)))
                }
                b = a0.mulDiv96(sqrtRatioLowerX96);
                assembly {
                    b := sub(b, div(mul(feePips, liquidity), FEE_COMPLEMENT))
                }
            }
            {
                // c = amount1Desired + liquidity * sqrtPrice / (1 - f) - liquidity * sqrtRatioLower
                uint256 c0 = liquidity.mulDiv96((MAX_FEE_PIPS * sqrtPriceX96) / FEE_COMPLEMENT);
                uint256 amount1Desired;
                assembly ("memory-safe") {
                    // amount1Desired = state.amount1Desired
                    amount1Desired := mload(add(state, 0x80))
                    // c0 = amount1Desired + liquidity * sqrtPrice / (1 - f)
                    c0 := add(amount1Desired, c0)
                }
                c = c0 - liquidity.mulDiv96(sqrtRatioLowerX96);
                assembly ("memory-safe") {
                    // `c` is always positive and greater than `amount1Desired`.
                    if lt(c, amount1Desired) {
                        // revert Math_Overflow()
                        mstore(0, 0x20236808)
                        revert(0x1c, 0x04)
                    }
                }
                b -= c0.mulDiv(FixedPoint96.Q96, state.sqrtRatioUpperX96);
            }
            assembly {
                a := shl(1, a)
                c := shl(1, c)
            }
        }
        // Given a root exists, the following calculations cannot realistically overflow/underflow.
        unchecked {
            uint256 numerator = FullMath.sqrt(b * b + a * c) + b;
            assembly {
                // `numerator` and `a` may be negative so use `sdiv`.
                sqrtPriceFinalX96 := sdiv(shl(96, numerator), a)
            }
        }
        // The final price must be greater than or equal to the price at the last tick.
        // However the calculated price may decrease if the ratio is close to optimal.
        assembly {
            // sqrtPriceFinalX96 = max(sqrtPriceFinalX96, sqrtPriceX96)
            sqrtPriceFinalX96 := xor(
                sqrtPriceX96,
                mul(xor(sqrtPriceX96, sqrtPriceFinalX96), gt(sqrtPriceFinalX96, sqrtPriceX96))
            )
        }
    }

    /// @dev Swap direction to achieve optimal deposit when the current price is in range
    /// @param amount0Desired The desired amount of token0 to be spent
    /// @param amount1Desired The desired amount of token1 to be spent
    /// @param sqrtPriceX96 sqrt(price) at the last tick of optimal swap
    /// @param sqrtRatioLowerX96 The lower sqrt(price) of the position in which to add liquidity
    /// @param sqrtRatioUpperX96 The upper sqrt(price) of the position in which to add liquidity
    /// @return The direction of the swap, true for token0 to token1, false for token1 to token0
    function isZeroForOneInRange(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 sqrtPriceX96,
        uint256 sqrtRatioLowerX96,
        uint256 sqrtRatioUpperX96
    ) private pure returns (bool) {
        // amount0 = liquidity * (sqrt(upper) - sqrt(current)) / (sqrt(upper) * sqrt(current))
        // amount1 = liquidity * (sqrt(current) - sqrt(lower))
        // amount0 * amount1 = liquidity * (sqrt(upper) - sqrt(current)) / (sqrt(upper) * sqrt(current)) * amount1
        //     = liquidity * (sqrt(current) - sqrt(lower)) * amount0
        unchecked {
            return
                amount0Desired.mulDiv96(sqrtPriceX96).mulDiv96(sqrtPriceX96 - sqrtRatioLowerX96) >
                amount1Desired.mulDiv(sqrtRatioUpperX96 - sqrtPriceX96, sqrtRatioUpperX96);
        }
    }

    /// @dev Swap direction to achieve optimal deposit
    /// @param amount0Desired The desired amount of token0 to be spent
    /// @param amount1Desired The desired amount of token1 to be spent
    /// @param sqrtPriceX96 sqrt(price) at the last tick of optimal swap
    /// @param sqrtRatioLowerX96 The lower sqrt(price) of the position in which to add liquidity
    /// @param sqrtRatioUpperX96 The upper sqrt(price) of the position in which to add liquidity
    /// @return The direction of the swap, true for token0 to token1, false for token1 to token0
    function isZeroForOne(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 sqrtPriceX96,
        uint256 sqrtRatioLowerX96,
        uint256 sqrtRatioUpperX96
    ) internal pure returns (bool) {
        // If the current price is below `sqrtRatioLowerX96`, only token0 is required.
        if (sqrtPriceX96 <= sqrtRatioLowerX96) return false;
        // If the current tick is above `sqrtRatioUpperX96`, only token1 is required.
        else if (sqrtPriceX96 >= sqrtRatioUpperX96) return true;
        else
            return
                isZeroForOneInRange(amount0Desired, amount1Desired, sqrtPriceX96, sqrtRatioLowerX96, sqrtRatioUpperX96);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "solady/src/utils/FixedPointMathLib.sol";

/// @title Contains 512-bit math functions
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol)
/// @author Credit to Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @notice Calculates floor(a脳b梅denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(a, b, denominator);
    }

    /// @notice Calculates ceil(a脳b梅denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDivUp(a, b, denominator);
    }

    /// @notice Calculates x * y / 2^96 with full precision.
    function mulDiv96(uint256 x, uint256 y) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            // 512-bit multiply `[prod1 prod0] = x * y`.
            // Compute the product mod `2**256` and mod `2**256 - 1`
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that `product = prod1 * 2**256 + prod0`.

            // Least significant 256 bits of the product.
            let prod0 := mul(x, y)
            let mm := mulmod(x, y, not(0))
            // Most significant 256 bits of the product.
            let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

            // Make sure the result is less than `2**256`.
            if iszero(gt(0x1000000000000000000000000, prod1)) {
                // Store the function selector of `FullMulDivFailed()`.
                mstore(0x00, 0xae47f702)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Divide [prod1 prod0] by 2^96.
            result := or(shr(96, prod0), shl(160, prod1))
        }
    }

    /// @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
    function sqrt(uint256 x) internal pure returns (uint256) {
        return FixedPointMathLib.sqrt(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title Library for efficient ternary operations
/// @author Aperture Finance
library TernaryLib {
    /// @notice Equivalent to the ternary operator: `condition ? a : b`
    function ternary(bool condition, uint256 a, uint256 b) internal pure returns (uint256 res) {
        assembly {
            res := xor(b, mul(xor(a, b), condition))
        }
    }

    /// @notice Equivalent to the ternary operator: `condition ? a : b`
    function ternary(bool condition, address a, address b) internal pure returns (address res) {
        assembly {
            res := xor(b, mul(xor(a, b), condition))
        }
    }

    /// @notice Equivalent to: `uint256(x < 0 ? -x : x)`
    function abs(int256 x) internal pure returns (uint256 y) {
        assembly {
            // mask = 0 if x >= 0 else -1
            let mask := sub(0, slt(x, 0))
            // If x >= 0, |x| = x = 0 ^ x
            // If x < 0, |x| = ~~|x| = ~(-|x| - 1) = ~(x - 1) = -1 ^ (x - 1)
            // Either case, |x| = mask ^ (x + mask)
            y := xor(mask, add(mask, x))
        }
    }

    /// @notice Equivalent to: `a < b ? a : b`
    function min(uint256 a, uint256 b) internal pure returns (uint256 res) {
        assembly {
            res := xor(b, mul(xor(a, b), lt(a, b)))
        }
    }

    /// @notice Equivalent to: `a > b ? a : b`
    function max(uint256 a, uint256 b) internal pure returns (uint256 res) {
        assembly {
            res := xor(b, mul(xor(a, b), gt(a, b)))
        }
    }

    /// @notice Equivalent to: `condition ? (b, a) : (a, b)`
    function switchIf(bool condition, uint256 a, uint256 b) internal pure returns (uint256, uint256) {
        assembly {
            let diff := mul(xor(a, b), condition)
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }

    /// @notice Equivalent to: `condition ? (b, a) : (a, b)`
    function switchIf(bool condition, address a, address b) internal pure returns (address, address) {
        assembly {
            let diff := mul(xor(a, b), condition)
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }

    /// @notice Sorts two addresses and returns them in ascending order
    function sort2(address a, address b) internal pure returns (address, address) {
        assembly {
            let diff := mul(xor(a, b), lt(b, a))
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }

    /// @notice Sorts two uint160s and returns them in ascending order
    function sort2(uint160 a, uint160 b) internal pure returns (uint160, uint160) {
        assembly {
            let diff := mul(xor(a, b), lt(b, a))
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/UnsafeMath.sol)
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(x, y)
        }
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := sub(x, y)
        }
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := mul(x, y)
        }
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := div(x, y)
        }
    }

    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// User defined value types are introduced in Solidity v0.8.8.
// https://blog.soliditylang.org/2021/09/27/user-defined-value-types/
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

type ERC20Callee is address;
using ERC20Caller for ERC20Callee global;

/// @title ERC20 Caller
/// @author Aperture Finance
/// @notice Gas efficient library to call ERC20 token assuming the token exists
library ERC20Caller {
    /// @dev Equivalent to `IERC20.totalSupply`
    /// @param token ERC20 token
    function totalSupply(ERC20Callee token) internal view returns (uint256 amount) {
        bytes4 selector = IERC20.totalSupply.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            // `totalSupply` should never revert according to the ERC20 standard.
            if iszero(staticcall(gas(), token, 0, 4, 0, 0x20)) {
                revert(0, 0)
            }
            amount := mload(0)
        }
    }

    /// @dev Equivalent to `IERC20.balanceOf`
    /// @param token ERC20 token
    /// @param account Account to check balance of
    function balanceOf(ERC20Callee token, address account) internal view returns (uint256 amount) {
        bytes4 selector = IERC20.balanceOf.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, account)
            // We use 36 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            // `balanceOf` should never revert according to the ERC20 standard.
            if iszero(staticcall(gas(), token, 0, 0x24, 0, 0x20)) {
                revert(0, 0)
            }
            amount := mload(0)
        }
    }

    /// @dev Equivalent to `IERC20.allowance`
    /// @param token ERC20 token
    /// @param owner Owner of the tokens
    /// @param spender Spender of the tokens
    function allowance(ERC20Callee token, address owner, address spender) internal view returns (uint256 amount) {
        bytes4 selector = IERC20.allowance.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, owner)
            mstore(0x24, spender)
            // We use 68 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            // `allowance` should never revert according to the ERC20 standard.
            if iszero(staticcall(gas(), token, 0, 0x44, 0, 0x20)) {
                revert(0, 0)
            }
            amount := mload(0)
            // Clear first 4 bytes of the free memory pointer.
            mstore(0x24, 0)
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./PoolAddress.sol";

/// @notice Provides validation for callbacks from Uniswap V3 Pools
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-periphery/blob/main/contracts/libraries/CallbackValidation.sol)
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, tokenA, tokenB, fee));
        require(msg.sender == address(pool));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address factory, PoolKey memory poolKey) internal view returns (IUniswapV3Pool pool) {
        pool = IUniswapV3Pool(PoolAddress.computeAddressSorted(factory, poolKey));
        require(msg.sender == address(pool));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The abi encoded PoolKey of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallbackCalldata(address factory, bytes calldata poolKey) internal view returns (address pool) {
        pool = PoolAddress.computeAddressCalldata(factory, poolKey);
        require(msg.sender == pool);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

import "solady/src/utils/SafeTransferLib.sol";
import {ERC20Callee} from "../libraries/ERC20Caller.sol";
import {WETHCallee} from "../libraries/WETHCaller.sol";
import {UniV3Immutables} from "./UniV3Immutables.sol";

abstract contract Payments is UniV3Immutables {
    using SafeTransferLib for address;

    error NotWETH9();
    error MismatchETH();

    receive() external payable {
        if (msg.sender != WETH9) revert NotWETH9();
    }

    /// @notice Pays an amount of ETH or ERC20 to a recipient
    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The address that will receive the payment
    /// @param value The amount to pay
    function pay(address token, address payer, address recipient, uint256 value) internal {
        // Receive native ETH
        if (token == WETH9 && msg.value != 0) {
            if (value != msg.value) revert MismatchETH();
            // Wrap it
            WETHCallee.wrap(WETH9).deposit(value);
            // Already received native ETH so return
            if (recipient == address(this)) return;
        }
        if (payer == address(this)) {
            // Send token to recipient
            token.safeTransfer(recipient, value);
        } else {
            // pull payment
            token.safeTransferFrom(payer, recipient, value);
        }
    }

    /// @dev Refunds an amount of ETH or ERC20 to a recipient, only called with balance the contract already has
    /// @param token The token to pay
    /// @param recipient The address that will receive the payment
    /// @param value The amount to pay
    function refund(address token, address recipient, uint256 value) internal {
        if (token == WETH9) {
            // Unwrap WETH
            WETHCallee.wrap(WETH9).withdraw(value);
            // Send native ETH to recipient
            recipient.safeTransferETH(value);
        } else {
            token.safeTransfer(recipient, value);
        }
    }

    /// @dev Pulls tokens from caller and approves NonfungiblePositionManager to spend
    function pullAndApprove(address token0, address token1, uint256 amount0Desired, uint256 amount1Desired) internal {
        if (amount0Desired != 0) {
            pay(token0, msg.sender, address(this), amount0Desired);
            token0.safeApprove(address(npm), amount0Desired);
        }
        if (amount1Desired != 0) {
            pay(token1, msg.sender, address(this), amount1Desired);
            token1.safeApprove(address(npm), amount1Desired);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// User defined value types are introduced in Solidity v0.8.8.
// https://blog.soliditylang.org/2021/09/27/user-defined-value-types/
pragma solidity >=0.8.8;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

type V3PoolCallee is address;
using PoolCaller for V3PoolCallee global;

/// @title Uniswap v3 Pool Caller
/// @author Aperture Finance
/// @notice Gas efficient library to call `IUniswapV3Pool` assuming the pool exists.
/// @dev Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// However, this is safe because "Note that you do not need to update the free memory pointer if there is no following
/// allocation, but you can only use memory starting from the current offset given by the free memory pointer."
/// according to https://docs.soliditylang.org/en/latest/assembly.html#memory-safety.
library PoolCaller {
    /// @dev Equivalent to `IUniswapV3Pool.fee`
    /// @param pool Uniswap v3 pool
    function fee(V3PoolCallee pool) internal view returns (uint24 f) {
        bytes4 selector = IUniswapV3PoolImmutables.fee.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 4, 0, 0x20)) {
                revert(0, 0)
            }
            f := mload(0)
        }
    }

    /// @dev Equivalent to `IUniswapV3Pool.tickSpacing`
    /// @param pool Uniswap v3 pool
    function tickSpacing(V3PoolCallee pool) internal view returns (int24 ts) {
        bytes4 selector = IUniswapV3PoolImmutables.tickSpacing.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 4, 0, 0x20)) {
                revert(0, 0)
            }
            ts := mload(0)
        }
    }

    /// @dev Equivalent to `IUniswapV3Pool.slot0`
    /// @param pool Uniswap v3 pool
    function slot0(
        V3PoolCallee pool
    )
        internal
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        bytes4 selector = IUniswapV3PoolState.slot0.selector;
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let fmp := mload(0x40)
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We copy up to 224 bytes of return data after fmp.
            if iszero(staticcall(gas(), pool, 0, 4, fmp, 0xe0)) {
                revert(0, 0)
            }
            sqrtPriceX96 := mload(fmp)
            tick := mload(add(fmp, 0x20))
            observationIndex := mload(add(fmp, 0x40))
            observationCardinality := mload(add(fmp, 0x60))
            observationCardinalityNext := mload(add(fmp, 0x80))
            feeProtocol := mload(add(fmp, 0xa0))
            unlocked := mload(add(fmp, 0xc0))
        }
    }

    /// @dev Equivalent to `(uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0()`
    /// @param pool Uniswap v3 pool
    function sqrtPriceX96AndTick(V3PoolCallee pool) internal view returns (uint160 sqrtPriceX96, int24 tick) {
        bytes4 selector = IUniswapV3PoolState.slot0.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 64 to copy up to 64 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 4, 0, 0x40)) {
                revert(0, 0)
            }
            sqrtPriceX96 := mload(0)
            tick := mload(0x20)
        }
    }

    /// @dev Equivalent to `IUniswapV3Pool.liquidity`
    /// @param pool Uniswap v3 pool
    function liquidity(V3PoolCallee pool) internal view returns (uint128 l) {
        bytes4 selector = IUniswapV3PoolState.liquidity.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 4, 0, 0x20)) {
                revert(0, 0)
            }
            l := mload(0)
        }
    }

    /// @dev Equivalent to `IUniswapV3Pool.tickBitmap`
    /// @param pool Uniswap v3 pool
    /// @param wordPos The key in the mapping containing the word in which the bit is stored
    function tickBitmap(V3PoolCallee pool, int16 wordPos) internal view returns (uint256 tickWord) {
        bytes4 selector = IUniswapV3PoolState.tickBitmap.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            // Pad int16 to 32 bytes.
            mstore(4, signextend(1, wordPos))
            // We use 36 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 0x24, 0, 0x20)) {
                revert(0, 0)
            }
            tickWord := mload(0)
        }
    }

    // info stored for each initialized individual tick
    struct Info {
        // the total position liquidity that references this tick
        uint128 liquidityGross;
        // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        int128 liquidityNet;
        // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute 鈥?the value depends on when the tick is initialized
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        // the cumulative tick value on the other side of the tick
        int56 tickCumulativeOutside;
        // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute 鈥?the value depends on when the tick is initialized
        uint160 secondsPerLiquidityOutsideX128;
        // the seconds spent on the other side of the tick (relative to the current tick)
        // only has relative meaning, not absolute 鈥?the value depends on when the tick is initialized
        uint32 secondsOutside;
        // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
        // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
        bool initialized;
    }

    /// @dev Equivalent to `IUniswapV3Pool.ticks`
    /// @param pool Uniswap v3 pool
    function ticks(V3PoolCallee pool, int24 tick) internal view returns (Info memory info) {
        bytes4 selector = IUniswapV3PoolState.ticks.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            // Pad int24 to 32 bytes.
            mstore(4, signextend(2, tick))
            // We use 36 because of the length of our calldata.
            // We copy up to 256 bytes of return data at info's pointer.
            if iszero(staticcall(gas(), pool, 0, 0x24, info, 0x100)) {
                revert(0, 0)
            }
        }
    }

    /// @dev Equivalent to `( , int128 liquidityNet, , , , , , ) = pool.ticks(tick)`
    /// @param pool Uniswap v3 pool
    function liquidityNet(V3PoolCallee pool, int24 tick) internal view returns (int128 ln) {
        bytes4 selector = IUniswapV3PoolState.ticks.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            // Pad int24 to 32 bytes.
            mstore(4, signextend(2, tick))
            // We use 36 because of the length of our calldata.
            // We use 0 and 64 to copy up to 64 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 0x24, 0, 0x40)) {
                revert(0, 0)
            }
            ln := mload(0x20)
        }
    }

    /// @dev Equivalent to `IUniswapV3Pool.swap`
    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param pool Uniswap v3 pool
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        V3PoolCallee pool,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) internal returns (int256 amount0, int256 amount1) {
        bytes4 selector = IUniswapV3PoolActions.swap.selector;
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 4), recipient)
            mstore(add(fmp, 0x24), zeroForOne)
            mstore(add(fmp, 0x44), amountSpecified)
            mstore(add(fmp, 0x64), sqrtPriceLimitX96)
            // Use 160 for the offset of `data` in calldata.
            mstore(add(fmp, 0x84), 0xa0)
            // length = data.length + 32
            let length := add(mload(data), 0x20)
            // Call the identity precompile 0x04 to copy `data` into calldata.
            pop(staticcall(gas(), 0x04, data, length, add(fmp, 0xa4), length))
            // We use `196 + data.length` for the length of our calldata.
            // We use 0 and 64 to copy up to 64 bytes of return data into the scratch space.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    eq(returndatasize(), 0x40), // Ensure `returndatasize` is 64.
                    call(gas(), pool, 0, fmp, add(0xa4, length), 0, 0x40)
                )
            ) {
                // It is safe to overwrite the free memory pointer 0x40 and the zero pointer 0x60 here before exiting
                // because a contract obtains a freshly cleared instance of memory for each message call.
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Read the return data.
            amount0 := mload(0)
            amount1 := mload(0x20)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@aperture_finance/uni-v3-lib/src/interfaces/INonfungiblePositionManager.sol";

/// @title Immutables of the Uniswap v3 Automation Manger
interface IUniV3Immutables {
    /// @notice Uniswap v3 Position Manager
    function npm() external view returns (INonfungiblePositionManager);

    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address payable);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "./SqrtPriceMath.sol";

/// @title Computes the result of a swap within ticks
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/SwapMath.sol)
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    uint256 internal constant MAX_FEE_PIPS = 1e6;

    /// @notice Computes the sqrt price target for the next swap step
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param sqrtPriceNextX96 The Q64.96 sqrt price for the next initialized tick
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @return sqrtRatioTargetX96 The price target for the next swap step
    function getSqrtRatioTarget(
        bool zeroForOne,
        uint160 sqrtPriceNextX96,
        uint160 sqrtPriceLimitX96
    ) internal pure returns (uint160 sqrtRatioTargetX96) {
        assembly {
            // a flag to toggle between sqrtPriceNextX96 and sqrtPriceLimitX96
            // when zeroForOne == true, nextOrLimit reduces to sqrtPriceNextX96 > sqrtPriceLimitX96
            // sqrtRatioTargetX96 = max(sqrtPriceNextX96, sqrtPriceLimitX96)
            // when zeroForOne == false, nextOrLimit reduces to sqrtPriceNextX96 <= sqrtPriceLimitX96
            // sqrtRatioTargetX96 = min(sqrtPriceNextX96, sqrtPriceLimitX96)
            let nextOrLimit := xor(gt(sqrtPriceNextX96, sqrtPriceLimitX96), iszero(zeroForOne))
            let symDiff := xor(sqrtPriceNextX96, sqrtPriceLimitX96)
            sqrtRatioTargetX96 := xor(sqrtPriceLimitX96, mul(symDiff, nextOrLimit))
        }
    }

    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    ) internal pure returns (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) {
        unchecked {
            bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
            uint256 feeComplement = MAX_FEE_PIPS - feePips;
            bool exactIn;
            uint256 amountRemainingAbs;
            assembly {
                // exactIn = 1 if amountRemaining >= 0 else 0
                exactIn := iszero(slt(amountRemaining, 0))
                // mask = 0 if amountRemaining >= 0 else -1
                let mask := sub(exactIn, 1)
                amountRemainingAbs := xor(mask, add(mask, amountRemaining))
            }

            if (exactIn) {
                uint256 amountRemainingLessFee = FullMath.mulDiv(amountRemainingAbs, feeComplement, MAX_FEE_PIPS);
                amountIn = zeroForOne
                    ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
                if (amountRemainingLessFee >= amountIn) {
                    // `amountIn` is capped by the target price
                    sqrtRatioNextX96 = sqrtRatioTargetX96;
                    feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, feeComplement);
                } else {
                    // exhaust the remaining amount
                    amountIn = amountRemainingLessFee;
                    sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                        sqrtRatioCurrentX96,
                        liquidity,
                        amountIn,
                        zeroForOne
                    );
                    // we didn't reach the target, so take the remainder of the maximum input as fee
                    feeAmount = amountRemainingAbs - amountIn;
                }
                amountOut = zeroForOne
                    ? SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false)
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
            } else {
                amountOut = zeroForOne
                    ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
                if (amountRemainingAbs >= amountOut) {
                    // `amountOut` is capped by the target price
                    sqrtRatioNextX96 = sqrtRatioTargetX96;
                } else {
                    // cap the output amount to not exceed the remaining output amount
                    amountOut = amountRemainingAbs;
                    sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                        sqrtRatioCurrentX96,
                        liquidity,
                        amountOut,
                        zeroForOne
                    );
                }
                amountIn = zeroForOne
                    ? SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true)
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
                feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, feeComplement);
            }
        }
    }

    /// @notice Computes the result of swapping some amount in given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input amount is remaining to be swapped in
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    function computeSwapStepExactIn(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint256 feePips
    ) internal pure returns (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut) {
        bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
        uint256 feeComplement = UnsafeMath.sub(MAX_FEE_PIPS, feePips);
        uint256 amountRemainingLessFee = FullMath.mulDiv(amountRemaining, feeComplement, MAX_FEE_PIPS);
        amountIn = zeroForOne
            ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
            : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
        if (amountRemainingLessFee >= amountIn) {
            // `amountIn` is capped by the target price
            sqrtRatioNextX96 = sqrtRatioTargetX96;
            // add the fee amount
            amountIn = FullMath.mulDivRoundingUp(amountIn, MAX_FEE_PIPS, feeComplement);
        } else {
            // exhaust the remaining amount
            amountIn = amountRemaining;
            sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                sqrtRatioCurrentX96,
                liquidity,
                amountRemainingLessFee,
                zeroForOne
            );
        }
        amountOut = zeroForOne
            ? SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false)
            : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
    }

    /// @notice Computes the result of swapping some amount out, given the parameters of the swap
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much output amount is remaining to be swapped out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    function computeSwapStepExactOut(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint256 feePips
    ) internal pure returns (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut) {
        bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
        amountOut = zeroForOne
            ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
            : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
        if (amountRemaining >= amountOut) {
            // `amountOut` is capped by the target price
            sqrtRatioNextX96 = sqrtRatioTargetX96;
        } else {
            // cap the output amount to not exceed the remaining output amount
            amountOut = amountRemaining;
            sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                sqrtRatioCurrentX96,
                liquidity,
                amountRemaining,
                zeroForOne
            );
        }
        amountIn = FullMath.mulDivRoundingUp(
            zeroForOne
                ? SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true)
                : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true),
            MAX_FEE_PIPS,
            UnsafeMath.sub(MAX_FEE_PIPS, feePips)
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.8;

import "./BitMath.sol";
import "./PoolCaller.sol";

/// @title Packed tick initialized state library
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/TickBitmap.sol)
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @dev round towards negative infinity
    function compress(int24 tick, int24 tickSpacing) internal pure returns (int24 compressed) {
        // compressed = tick / tickSpacing;
        // if (tick < 0 && tick % tickSpacing != 0) compressed--;
        assembly {
            compressed := sub(
                sdiv(tick, tickSpacing),
                // if (tick < 0 && tick % tickSpacing != 0) then tick % tickSpacing < 0, vice versa
                slt(smod(tick, tickSpacing), 0)
            )
        }
    }

    /// @notice Computes the word position and the bit position given a tick.
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        assembly {
            // signed arithmetic shift right
            wordPos := sar(8, tick)
            bitPos := and(tick, 255)
        }
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    /// @param tickSpacing The spacing between usable ticks
    function flipTick(mapping(int16 => uint256) storage self, int24 tick, int24 tickSpacing) internal {
        assembly ("memory-safe") {
            // ensure that the tick is spaced
            if smod(tick, tickSpacing) {
                revert(0, 0)
            }
            tick := sdiv(tick, tickSpacing)
            // calculate the storage slot corresponding to the tick
            // wordPos = tick >> 8
            mstore(0, sar(8, tick))
            mstore(0x20, self.slot)
            // the slot of self[wordPos] is keccak256(abi.encode(wordPos, self.slot))
            let slot := keccak256(0, 0x40)
            // mask = 1 << bitPos = 1 << (tick % 256)
            // self[wordPos] ^= mask
            sstore(slot, xor(sload(slot), shl(and(tick, 255), 1)))
        }
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = compress(tick, tickSpacing);
        uint256 masked;

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            // mask = (1 << (bitPos + 1)) - 1
            // (bitPos + 1) may be 256 but fine
            // masked = self[wordPos] & mask
            assembly ("memory-safe") {
                mstore(0, wordPos)
                mstore(0x20, self.slot)
                let mask := sub(shl(add(bitPos, 1), 1), 1)
                masked := and(sload(keccak256(0, 0x40)), mask)
                initialized := gt(masked, 0)
            }

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            if (initialized) {
                uint8 msb = BitMath.mostSignificantBit(masked);
                assembly {
                    next := mul(add(sub(compressed, bitPos), msb), tickSpacing)
                }
            } else {
                assembly {
                    next := mul(sub(compressed, bitPos), tickSpacing)
                }
            }
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            unchecked {
                ++compressed;
            }
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the left of the bitPos
            // mask = ~((1 << bitPos) - 1)
            // masked = self[wordPos] & mask
            assembly ("memory-safe") {
                mstore(0, wordPos)
                mstore(0x20, self.slot)
                let mask := not(sub(shl(bitPos, 1), 1))
                masked := and(sload(keccak256(0, 0x40)), mask)
                initialized := gt(masked, 0)
            }

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            if (initialized) {
                uint8 lsb = BitMath.leastSignificantBit(masked);
                assembly {
                    next := mul(add(sub(compressed, bitPos), lsb), tickSpacing)
                }
            } else {
                assembly {
                    next := mul(add(sub(compressed, bitPos), 255), tickSpacing)
                }
            }
        }
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param pool Uniswap v3 pool
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @param lastWordPos The last accessed word position in the Bitmap. Set it to `type(int16).min` for the first call.
    /// @param lastWord The last accessed word in the Bitmap
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    /// @return wordPos The word position of the next initialized tick in the Bitmap
    /// @return tickWord The word of the next initialized tick in the Bitmap
    function nextInitializedTickWithinOneWord(
        V3PoolCallee pool,
        int24 tick,
        int24 tickSpacing,
        bool lte,
        int16 lastWordPos,
        uint256 lastWord
    ) internal view returns (int24 next, bool initialized, int16 wordPos, uint256 tickWord) {
        int24 compressed = compress(tick, tickSpacing);
        uint8 bitPos;
        uint256 masked;

        if (lte) {
            (wordPos, bitPos) = position(compressed);
            // Reuse the same word if the position doesn't change
            tickWord = wordPos == lastWordPos ? lastWord : pool.tickBitmap(wordPos);
            // all the 1s at or to the right of the current bitPos
            // mask = (1 << (bitPos + 1)) - 1
            // (bitPos + 1) may be 256 but fine
            assembly {
                let mask := sub(shl(add(bitPos, 1), 1), 1)
                masked := and(tickWord, mask)
                initialized := gt(masked, 0)
            }

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            if (initialized) {
                uint8 msb = BitMath.mostSignificantBit(masked);
                assembly {
                    next := mul(add(sub(compressed, bitPos), msb), tickSpacing)
                }
            } else {
                assembly {
                    next := mul(sub(compressed, bitPos), tickSpacing)
                }
            }
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            unchecked {
                (wordPos, bitPos) = position(++compressed);
            }
            // Reuse the same word if the position doesn't change
            tickWord = wordPos == lastWordPos ? lastWord : pool.tickBitmap(wordPos);
            // all the 1s at or to the left of the bitPos
            // mask = ~((1 << bitPos) - 1)
            assembly {
                let mask := not(sub(shl(bitPos, 1), 1))
                masked := and(tickWord, mask)
                initialized := gt(masked, 0)
            }

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            if (initialized) {
                uint8 lsb = BitMath.leastSignificantBit(masked);
                assembly {
                    next := mul(add(sub(compressed, bitPos), lsb), tickSpacing)
                }
            } else {
                assembly {
                    next := mul(add(sub(compressed, bitPos), 255), tickSpacing)
                }
            }
        }
    }

    /// @notice Returns the next initialized tick not limited to the same word as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @dev It is assumed that the next initialized tick exists.
    /// @param pool Uniswap v3 pool
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @param lastWordPos The last accessed word position in the Bitmap. Set it to `type(int16).min` for the first call.
    /// @param lastWord The last accessed word in the Bitmap
    /// @return next The next initialized tick
    /// @return wordPos The word position of the next initialized tick in the Bitmap
    /// @return tickWord The word of the next initialized tick in the Bitmap
    function nextInitializedTick(
        V3PoolCallee pool,
        int24 tick,
        int24 tickSpacing,
        bool lte,
        int16 lastWordPos,
        uint256 lastWord
    ) internal view returns (int24 next, int16 wordPos, uint256 tickWord) {
        int24 compressed = compress(tick, tickSpacing);
        uint8 bitPos;
        uint256 masked;
        uint8 sb;
        if (lte) {
            (wordPos, bitPos) = position(compressed);
            // Reuse the same word if the position doesn't change
            tickWord = wordPos == lastWordPos ? lastWord : pool.tickBitmap(wordPos);
            // all the 1s at or to the right of the current bitPos
            // mask = (1 << (bitPos + 1)) - 1
            // (bitPos + 1) may be 256 but fine
            assembly {
                let mask := sub(shl(add(bitPos, 1), 1), 1)
                masked := and(tickWord, mask)
            }
            while (masked == 0) {
                // Always query the next word to the left
                unchecked {
                    masked = tickWord = pool.tickBitmap(--wordPos);
                }
            }
            sb = BitMath.mostSignificantBit(masked);
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            unchecked {
                (wordPos, bitPos) = position(++compressed);
            }
            // Reuse the same word if the position doesn't change
            tickWord = wordPos == lastWordPos ? lastWord : pool.tickBitmap(wordPos);
            // all the 1s at or to the left of the bitPos
            // mask = ~((1 << bitPos) - 1)
            assembly {
                let mask := not(sub(shl(bitPos, 1), 1))
                masked := and(tickWord, mask)
            }
            while (masked == 0) {
                // Always query the next word to the right
                unchecked {
                    masked = tickWord = pool.tickBitmap(++wordPos);
                }
            }
            sb = BitMath.leastSignificantBit(masked);
        }
        assembly {
            // next = (wordPos * 256 + sb) * tickSpacing
            next := mul(add(shl(8, wordPos), sb), tickSpacing)
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./TernaryLib.sol";

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol)
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = 887272;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    /// @dev A threshold used for optimized bounds check, equals `MAX_SQRT_RATIO - MIN_SQRT_RATIO - 1`
    uint160 internal constant MAX_SQRT_RATIO_MINUS_MIN_SQRT_RATIO_MINUS_ONE =
        1461446703485210103287273052203988822378723970342 - 4295128739 - 1;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            int256 tick256;
            assembly {
                // sign extend to make tick an int256 in twos complement
                tick256 := signextend(2, tick)
            }
            uint256 absTick = TernaryLib.abs(tick256);
            /// @solidity memory-safe-assembly
            assembly {
                // Equivalent: if (absTick > MAX_TICK) revert("T");
                if gt(absTick, MAX_TICK) {
                    // selector "Error(string)", [0x1c, 0x20)
                    mstore(0, 0x08c379a0)
                    // abi encoding offset
                    mstore(0x20, 0x20)
                    // reason string length 1 and 'T', [0x5f, 0x61)
                    mstore(0x41, 0x0154)
                    // 4 byte selector + 32 byte offset + 32 byte length + 1 byte reason
                    revert(0x1c, 0x45)
                }
            }

            // Equivalent: ratio = 2**128 / sqrt(1.0001) if absTick & 0x1 else 1 << 128
            uint256 ratio;
            assembly {
                ratio := and(
                    shr(
                        // 128 if absTick & 0x1 else 0
                        shl(7, and(absTick, 0x1)),
                        // upper 128 bits of 2**256 / sqrt(1.0001) where the 128th bit is 1
                        0xfffcb933bd6fad37aa2d162d1a59400100000000000000000000000000000000
                    ),
                    0x1ffffffffffffffffffffffffffffffff // mask lower 129 bits
                )
            }
            // Iterate through 1th to 19th bit of absTick because MAX_TICK < 2**20
            // Equivalent to:
            //      for i in range(1, 20):
            //          if absTick & 2 ** i:
            //              ratio = ratio * (2 ** 128 / 1.0001 ** (2 ** (i - 1))) / 2 ** 128
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            // if (tick > 0) ratio = type(uint256).max / ratio;
            assembly {
                if sgt(tick256, 0) {
                    ratio := div(not(0), ratio)
                }
            }

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            assembly {
                sqrtPriceX96 := shr(32, add(ratio, 0xffffffff))
            }
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Equivalent: if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO) revert("R");
        // second inequality must be >= because the price can never reach the price at the max tick
        /// @solidity memory-safe-assembly
        assembly {
            // if sqrtPriceX96 < MIN_SQRT_RATIO, the `sub` underflows and `gt` is true
            // if sqrtPriceX96 >= MAX_SQRT_RATIO, sqrtPriceX96 - MIN_SQRT_RATIO > MAX_SQRT_RATIO - MAX_SQRT_RATIO - 1
            if gt(sub(sqrtPriceX96, MIN_SQRT_RATIO), MAX_SQRT_RATIO_MINUS_MIN_SQRT_RATIO_MINUS_ONE) {
                // selector "Error(string)", [0x1c, 0x20)
                mstore(0, 0x08c379a0)
                // abi encoding offset
                mstore(0x20, 0x20)
                // reason string length 1 and 'R', [0x5f, 0x61)
                mstore(0x41, 0x0152)
                // 4 byte selector + 32 byte offset + 32 byte length + 1 byte reason
                revert(0x1c, 0x45)
            }
        }

        // Find the most significant bit of `sqrtPriceX96`, 160 > msb >= 32.
        uint8 msb;
        assembly {
            let x := sqrtPriceX96
            msb := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            msb := or(msb, shl(6, lt(0xffffffffffffffff, shr(msb, x))))
            msb := or(msb, shl(5, lt(0xffffffff, shr(msb, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            x := shr(msb, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            msb := or(
                msb,
                byte(
                    shr(251, mul(x, shl(224, 0x07c4acdd))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f
                )
            )
        }

        // 2**(msb - 95) > sqrtPrice >= 2**(msb - 96)
        // the integer part of log_2(sqrtPrice) * 2**64 = (msb - 96) << 64, 8.64 number
        int256 log_2X64;
        assembly {
            log_2X64 := shl(64, sub(msb, 96))

            // Get the first 128 significant figures of `sqrtPriceX96`.
            // r = sqrtPriceX96 / 2**(msb - 127), where 2**128 > r >= 2**127
            // sqrtPrice = 2**(msb - 96) * r / 2**127, in floating point math
            // Shift left first because 160 > msb >= 32. If we shift right first, we'll lose precision.
            let r := shr(sub(msb, 31), shl(96, sqrtPriceX96))

            // Approximate `log_2X64` to 14 binary digits after decimal
            // log_2X64 = (msb - 96) * 2**64 + f_0 * 2**63 + f_1 * 2**62 + ......
            // sqrtPrice**2 = 2**(2 * (msb - 96)) * (r / 2**127)**2 = 2**(2 * log_2X64 / 2**64) = 2**(2 * (msb - 96) + f_0)
            // 2**f_0 = (r / 2**127)**2 = r**2 / 2**255 * 2
            // f_0 = 1 if (r**2 >= 2**255) else 0
            // sqrtPrice**2 = 2**(2 * (msb - 96) + f_0) * r**2 / 2**(254 + f_0) = 2**(2 * (msb - 96) + f_0) * r' / 2**127
            // r' = r**2 / 2**(127 + f_0)
            // sqrtPrice**4 = 2**(4 * (msb - 96) + 2 * f_0) * (r' / 2**127)**2
            //     = 2**(4 * log_2X64 / 2**64) = 2**(4 * (msb - 96) + 2 * f_0 + f_1)
            // 2**(f_1) = (r' / 2**127)**2
            // f_1 = 1 if (r'**2 >= 2**255) else 0

            // Check whether r >= sqrt(2) * 2**127
            // 2**256 > r**2 >= 2**254
            let square := mul(r, r)
            // f = (r**2 >= 2**255)
            let f := slt(square, 0)
            // r = r**2 >> 128 if r**2 >= 2**255 else r**2 >> 127
            r := shr(add(127, f), square)
            log_2X64 := or(shl(63, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(62, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(61, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(60, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(59, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(58, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(57, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(56, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(55, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(54, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(53, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(52, f), log_2X64)

            square := mul(r, r)
            f := slt(square, 0)
            r := shr(add(127, f), square)
            log_2X64 := or(shl(51, f), log_2X64)

            log_2X64 := or(shl(50, slt(mul(r, r), 0)), log_2X64)
        }

        // sqrtPrice = sqrt(1.0001^tick)
        // tick = log_{sqrt(1.0001)}(sqrtPrice) = log_2(sqrtPrice) / log_2(sqrt(1.0001))
        // 2**64 / log_2(sqrt(1.0001)) = 255738958999603826347141
        int24 tickLow;
        int24 tickHi;
        assembly {
            let log_sqrt10001 := mul(log_2X64, 255738958999603826347141) // 128.128 number
            tickLow := shr(128, sub(log_sqrt10001, 3402992956809132418596140100660247210))
            tickHi := shr(128, add(log_sqrt10001, 291339464771989622907027621153398088495))
        }

        // Equivalent: tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        if (tickLow == tickHi) {
            tick = tickHi;
        } else {
            uint160 sqrtRatioAtTickHi = getSqrtRatioAtTick(tickHi);
            assembly {
                tick := sub(tickHi, gt(sqrtRatioAtTickHi, sqrtPriceX96))
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*                       CUSTOM ERRORS                        */

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*                         CONSTANTS                          */

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*              SIMPLIFIED FIXED POINT OPERATIONS             */

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    // Store the function selector of `ExpOverflow()`.
                    mstore(0x00, 0xa37bfec9)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-陆 ln 2, 陆 ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k)
            );
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    // Store the function selector of `LnWadUndefined()`.
                    mstore(0x00, 0x1615e638)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)), 96)
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549鈥n            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*                  GENERAL NUMBER UTILITIES                  */

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2蟺.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {} 1 {} {
                // 512-bit multiply `[prod1 prod0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = prod1 * 2**256 + prod0`.

                // Least significant 256 bits of the product.
                let prod0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(d) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, d)
                    break       
                }

                // Make sure the result is less than `2**256`.
                // Also prevents `d == 0`.
                if iszero(gt(d, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from `[prod1 prod0]`.
                // Compute remainder using mulmod.
                let remainder := mulmod(x, y, d)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of `d`.
                // Compute largest power of two divisor of `d`.
                // Always greater or equal to 1.
                let twos := and(d, sub(0, d))
                // Divide d by power of two.
                d := div(d, twos)
                // Divide [prod1 prod0] by the factors of two.
                prod0 := div(prod0, twos)
                // Shift in bits from `prod1` into `prod0`. For this we need
                // to flip `twos` such that it is `2**256 / twos`.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(d, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the cube root of `x`.
    /// Credit to bout3fiddy and pcaversaccio under AGPLv3 license:
    /// https://github.com/pcaversaccio/snekmate/blob/main/src/utils/Math.vy
    function cbrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))

            z := shl(add(div(r, 3), lt(0xf, shr(r, x))), 0xff)
            z := div(z, byte(mod(r, 3), shl(232, 0x7f624b)))

            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)

            z := sub(z, lt(div(x, mul(z, z)), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 58)) {
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            for { result := 1 } x {} {
                result := mul(result, x)
                x := sub(x, 1)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))),
                0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue)
        internal
        pure
        returns (uint256 z)
    {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for { z := x } y {} {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*                   RAW NUMBER OPERATIONS                    */

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// User defined value types are introduced in Solidity v0.8.8.
// https://blog.soliditylang.org/2021/09/27/user-defined-value-types/
pragma solidity ^0.8.8;

import "solmate/src/tokens/WETH.sol";

type WETHCallee is address;
using WETHCaller for WETHCallee global;

/// @title WETH Caller
/// @author Aperture Finance
/// @notice Gas efficient library to call WETH assuming the contract exists.
library WETHCaller {
    /// @dev Equivalent to `WETH.deposit`
    /// @param weth WETH contract
    /// @param value Amount of ETH to deposit
    function deposit(WETHCallee weth, uint256 value) internal {
        bytes4 selector = WETH.deposit.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            if iszero(call(gas(), weth, value, 0, 4, 0, 0)) {
                revert(0, 0)
            }
        }
    }

    /// @dev Equivalent to `WETH.withdraw`
    /// @param weth WETH contract
    /// @param amount Amount of WETH to withdraw
    function withdraw(WETHCallee weth, uint256 amount) internal {
        bytes4 selector = WETH.withdraw.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            mstore(4, amount)
            // We use 36 because of the length of our calldata.
            if iszero(call(gas(), weth, 0, 0, 0x24, 0, 0)) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

import {INonfungiblePositionManager as INPM} from "@aperture_finance/uni-v3-lib/src/interfaces/INonfungiblePositionManager.sol";
import {IUniV3Immutables} from "../interfaces/IUniV3Immutables.sol";

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract UniV3Immutables is IUniV3Immutables {
    /// @notice Uniswap v3 Position Manager
    INPM public immutable npm;
    /// @notice Uniswap v3 Factory
    address public immutable factory;
    /// @notice Wrapped ETH
    address payable public immutable override WETH9;

    constructor(INPM nonfungiblePositionManager) {
        npm = nonfungiblePositionManager;
        factory = nonfungiblePositionManager.factory();
        WETH9 = payable(nonfungiblePositionManager.WETH9());
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "@uniswap/v3-core/contracts/libraries/SafeCast.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

import "./FullMath.sol";
import "./TernaryLib.sol";
import "./UnsafeMath.sol";

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/SqrtPriceMath.sol)
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using UnsafeMath for *;
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            unchecked {
                uint256 product = amount * sqrtPX96;
                // checks for overflow
                if (product.div(amount) == sqrtPX96) {
                    // denominator = liquidity + amount * sqrtPX96
                    uint256 denominator = numerator1 + product;
                    // checks for overflow
                    if (denominator >= numerator1)
                        // always fits in 160 bits
                        return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
                }
            }

            // liquidity / (liquidity / sqrtPX96 + amount)
            return uint160(numerator1.divRoundingUp(numerator1.div(sqrtPX96) + amount));
        } else {
            uint256 denominator;
            assembly ("memory-safe") {
                // if the product overflows, we know the denominator underflows
                // in addition, we must check that the denominator does not underflow
                let product := mul(amount, sqrtPX96)
                if iszero(and(eq(div(product, amount), sqrtPX96), gt(numerator1, product))) {
                    revert(0, 0)
                }
                denominator := sub(numerator1, product)
            }
            return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return nextSqrtPrice The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160 nextSqrtPrice) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? (amount << FixedPoint96.RESOLUTION).div(liquidity)
                    : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
            );

            nextSqrtPrice = (sqrtPX96 + quotient).toUint160();
        } else {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? (amount << FixedPoint96.RESOLUTION).divRoundingUp(liquidity)
                    : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
            );
            assembly ("memory-safe") {
                if iszero(gt(sqrtPX96, quotient)) {
                    revert(0, 0)
                }
                // always fits 160 bits
                nextSqrtPrice := sub(sqrtPX96, quotient)
            }
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        assembly ("memory-safe") {
            if or(iszero(sqrtPX96), iszero(liquidity)) {
                revert(0, 0)
            }
        }
        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
                : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        assembly ("memory-safe") {
            if or(iszero(sqrtPX96), iszero(liquidity)) {
                revert(0, 0)
            }
        }
        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
                : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price assumed to be lower otherwise swapped
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2(sqrtRatioAX96, sqrtRatioBX96);
        assembly ("memory-safe") {
            if iszero(sqrtRatioAX96) {
                revert(0, 0)
            }
        }
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96.sub(sqrtRatioAX96);
        /**
         * Equivalent to:
         *   roundUp
         *       ? FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96).divRoundingUp(sqrtRatioAX96)
         *       : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
         * If `md = mulDiv(n1, n2, srb) == mulDivRoundingUp(n1, n2, srb)`, then `mulmod(n1, n2, srb) == 0`.
         * Add `roundUp && md % sra > 0` to `div(md, sra)`.
         * If `md = mulDiv(n1, n2, srb)` and `mulDivRoundingUp(n1, n2, srb)` differs by 1 and `sra > 0`,
         * then `(md + 1).divRoundingUp(sra) == md.div(sra) + 1` whether `sra` fully divides `md` or not.
         */
        uint256 mulDivResult = FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96);
        assembly {
            amount0 := add(
                div(mulDivResult, sqrtRatioAX96),
                and(gt(or(mod(mulDivResult, sqrtRatioAX96), mulmod(numerator1, numerator2, sqrtRatioBX96)), 0), roundUp)
            )
        }
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price assumed to be lower otherwise swapped
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2(sqrtRatioAX96, sqrtRatioBX96);
        uint256 numerator = sqrtRatioBX96.sub(sqrtRatioAX96);
        uint256 denominator = FixedPoint96.Q96;
        /**
         * Equivalent to:
         *   amount1 = roundUp
         *       ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
         *       : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
         * Cannot overflow because `type(uint128).max * type(uint160).max >> 96 < (1 << 192)`.
         */
        amount1 = FullMath.mulDiv96(liquidity, numerator);
        assembly {
            amount1 := add(amount1, and(gt(mulmod(liquidity, numerator, denominator), 0), roundUp))
        }
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        /**
         * Equivalent to:
         *   amount0 = liquidity < 0
         *       ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
         *       : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
         */
        bool sign;
        uint256 mask;
        uint128 liquidityAbs;
        assembly {
            // In case the upper bits are not clean.
            liquidity := signextend(15, liquidity)
            // sign = 1 if liquidity >= 0 else 0
            sign := iszero(slt(liquidity, 0))
            // mask = 0 if liquidity >= 0 else -1
            mask := sub(sign, 1)
            liquidityAbs := xor(mask, add(mask, liquidity))
        }
        // amount0Abs = liquidity / sqrt(lower) - liquidity / sqrt(upper) < type(uint224).max
        // always fits in 224 bits, no need for toInt256()
        uint256 amount0Abs = getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, liquidityAbs, sign);
        assembly {
            // If liquidity >= 0, amount0 = |amount0| = 0 ^ |amount0|
            // If liquidity < 0, amount0 = -|amount0| = ~|amount0| + 1 = (-1) ^ |amount0| - (-1)
            amount0 := sub(xor(amount0Abs, mask), mask)
        }
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        /**
         * Equivalent to:
         *   amount1 = liquidity < 0
         *       ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
         *       : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
         */
        bool sign;
        uint256 mask;
        uint128 liquidityAbs;
        assembly {
            // In case the upper bits are not clean.
            liquidity := signextend(15, liquidity)
            // sign = 1 if liquidity >= 0 else 0
            sign := iszero(slt(liquidity, 0))
            // mask = 0 if liquidity >= 0 else -1
            mask := sub(sign, 1)
            liquidityAbs := xor(mask, add(mask, liquidity))
        }
        // amount1Abs = liquidity * (sqrt(upper) - sqrt(lower)) < type(uint192).max
        // always fits in 192 bits, no need for toInt256()
        uint256 amount1Abs = getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, liquidityAbs, sign);
        assembly {
            // If liquidity >= 0, amount1 = |amount1| = 0 ^ |amount1|
            // If liquidity < 0, amount1 = -|amount1| = ~|amount1| + 1 = (-1) ^ |amount1| - (-1)
            amount1 := sub(xor(amount1Abs, mask), mask)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title BitMath
/// @author Aperture Finance
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBit.sol)
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     If x == 0, r == 0. Otherwise
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        assembly {
            // r = x >= 2**128 ? 128 : 0
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            // r += (x >> r) >= 2**64 ? 64 : 0
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            // r += (x >> r) >= 2**32 ? 32 : 0
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // https://graphics.stanford.edu/~seander/bithacks.html#IntegerLogDeBruijn
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            r := or(
                r,
                byte(
                    shr(251, mul(x, shl(224, 0x07c4acdd))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f
                )
            )
        }
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     If x == 0, r == 0. Otherwise
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        assembly {
            // Isolate the least significant bit, x = x & -x = x & (~x + 1)
            x := and(x, sub(0, x))

            // r = x >= 2**128 ? 128 : 0
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            // r += (x >> r) >= 2**64 ? 64 : 0
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            // r += (x >> r) >= 2**32 ? 32 : 0
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // https://graphics.stanford.edu/~seander/bithacks.html#ZerosOnRightMultLookup
            r := or(
                r,
                byte(
                    shr(251, mul(shr(r, x), shl(224, 0x077cb531))),
                    0x00011c021d0e18031e16140f191104081f1b0d17151310071a0c12060b050a09
                )
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}