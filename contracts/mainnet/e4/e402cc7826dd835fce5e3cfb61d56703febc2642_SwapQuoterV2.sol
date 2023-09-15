// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PoolQuoterV1} from "./PoolQuoterV1.sol";
import {ISwapQuoterV1, LimitedToken, SwapQuery, Pool} from "../interfaces/ISwapQuoterV1.sol";
import {ISwapQuoterV2} from "../interfaces/ISwapQuoterV2.sol";
import {Action, ActionLib} from "../libs/Structs.sol";

import {EnumerableSet} from "@openzeppelin/contracts-4.5.0/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts-4.5.0/access/Ownable.sol";

contract SwapQuoterV2 is PoolQuoterV1, Ownable, ISwapQuoterV2 {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Error when trying to add a pool that has been added already.
    error SwapQuoterV2__DuplicatedPool(address pool);

    /// @notice Error when trying to remove a pool that has not been added.
    error SwapQuoterV2__UnknownPool(address pool);

    /// @notice Emitted when a pool is added to SwapQuoterV2.
    event PoolAdded(address bridgeToken, PoolType poolType, address pool);

    /// @notice Emitted when a pool is removed from SwapQuoterV2.
    event PoolRemoved(address bridgeToken, PoolType poolType, address pool);

    /// @notice Emitted when the SynapseRouter contract is updated.
    event SynapseRouterUpdated(address synapseRouter);

    /// @notice Defines the type of supported liquidity pool.
    /// - Default: pool that implements the IDefaultPool interface, which is either the StableSwap pool
    /// or a wrapper contract around the non-standard pool that conforms to the interface.
    /// - Linked: LinkedPool contract, which is a wrapper for arbitrary amount of liquidity pools to
    /// be used for multi-hop swaps.
    enum PoolType {
        Default,
        Linked
    }

    /// @notice Struct that is used for storing the whitelisted liquidity pool for a bridge token.
    /// @dev Occupies a single storage slot.
    /// @param poolType     Type of the pool: Default or Linked.
    /// @param pool         Address of the whitelisted pool.
    struct TypedPool {
        PoolType poolType;
        address pool;
    }

    /// @notice Struct that is used as a argument/return value for pool management functions.
    /// Therefore, it is not used internally and does not occupy any storage slots.
    /// @dev `bridgeToken` can be set to zero, in which case struct defines a pool
    /// that could be used for swaps on origin chain only.
    /// @param bridgeToken  Address of the bridge token.
    /// @param poolType     Type of the pool: Default or Linked.
    /// @param pool         Address of the whitelisted pool.
    struct BridgePool {
        address bridgeToken;
        PoolType poolType;
        address pool;
    }

    // ══════════════════════════════════════════════════ STORAGE ══════════════════════════════════════════════════════

    /// @notice Address of the SynapseRouter contract, which is used as "Router Adapter" for doing
    /// swaps through Default Pools (or handling ETH).
    address public synapseRouter;

    /// @dev Set of Default Pools that could be used for swaps on origin chain only
    EnumerableSet.AddressSet internal _originDefaultPools;
    /// @dev Set of Linked Pools that could be used for swaps on origin chain only
    EnumerableSet.AddressSet internal _originLinkedPools;

    /// @dev Mapping from a bridge token into a whitelisted liquidity pool for the token.
    /// Could be used for swaps on both origin and destination chains.
    /// For swaps on destination chains, this is the only pool that could be used for swaps for the given token.
    mapping(address => TypedPool) internal _bridgePools;
    /// @dev Set of bridge tokens with whitelisted liquidity pools (keys for `_bridgePools` mapping)
    EnumerableSet.AddressSet internal _bridgeTokens;

    constructor(
        address synapseRouter_,
        address defaultPoolCalc_,
        address weth_,
        address owner_
    ) PoolQuoterV1(defaultPoolCalc_, weth_) {
        setSynapseRouter(synapseRouter_);
        transferOwnership(owner_);
    }

    // ═══════════════════════════════════════════ QUOTER V2 MANAGEMENT ════════════════════════════════════════════════

    /// @notice Allows to add a list of pools to SwapQuoterV2.
    /// - If bridgeToken is zero, the pool is added to the set of "origin pools" corresponding to the pool type:
    /// Default Pools for PoolType.Default, Linked Pools for PoolType.Linked.
    /// - Otherwise, the pool is added as the whitelisted pool for the bridge token. The pool could be used for swaps
    /// on both origin and destination chains.
    /// > Note: to update the whitelisted pool for the bridge token, supply the new pool with the same bridge token.
    /// > It is not required to remove the old pool first.
    /// @dev Will revert, if the pool is already added.
    function addPools(BridgePool[] memory pools) external onlyOwner {
        unchecked {
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < pools.length; ++i) {
                _addPool(pools[i]);
            }
        }
    }

    /// @notice Allows to remove a list of pools from SwapQuoterV2.
    /// - If bridgeToken is zero, the pool is removed from the set of "origin pools" corresponding to the pool type:
    /// Default Pools for PoolType.Default, Linked Pools for PoolType.Linked.
    /// - Otherwise, the pool is removed as the whitelisted pool for the bridge token.
    /// @dev Will revert, if the pool is not added.
    function removePools(BridgePool[] memory pools) external onlyOwner {
        unchecked {
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < pools.length; ++i) {
                _removePool(pools[i]);
            }
        }
    }

    /// @notice Allows to set the SynapseRouter contract, which is used as "Router Adapter" for doing
    /// swaps through Default Pools (or handling ETH).
    /// Note: this will not affect the old SynapseRouter contract which still uses this Quoter, as the old SynapseRouter
    /// could handle the requests with the new SynapseRouter as external "Router Adapter".
    function setSynapseRouter(address synapseRouter_) public onlyOwner {
        synapseRouter = synapseRouter_;
        emit SynapseRouterUpdated(synapseRouter_);
    }

    // ══════════════════════════════════════════════ QUOTER V2 VIEWS ══════════════════════════════════════════════════

    /// @notice Returns the list of Default Pools that could be used for swaps on origin chain only.
    function getOriginDefaultPools() external view returns (address[] memory originDefaultPools) {
        return _originDefaultPools.values();
    }

    /// @notice Returns the list of Linked Pools that could be used for swaps on origin chain only.
    function getOriginLinkedPools() external view returns (address[] memory originLinkedPools) {
        return _originLinkedPools.values();
    }

    /// @notice Returns the list of bridge tokens with whitelisted liquidity pools.
    /// The pools could be used for swaps on both origin and destination chains.
    function getBridgePools() external view returns (BridgePool[] memory bridgePools) {
        uint256 amtBridgePools = _bridgeTokens.length();
        bridgePools = new BridgePool[](amtBridgePools);
        unchecked {
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < amtBridgePools; ++i) {
                address bridgeToken = _bridgeTokens.at(i);
                TypedPool memory typedPool = _bridgePools[bridgeToken];
                bridgePools[i] = BridgePool({
                    bridgeToken: bridgeToken,
                    poolType: typedPool.poolType,
                    pool: typedPool.pool
                });
            }
        }
    }

    // ═════════════════════════════════════════════ GENERAL QUOTES V1 ═════════════════════════════════════════════════

    /// @inheritdoc ISwapQuoterV1
    function findConnectedTokens(LimitedToken[] memory bridgeTokensIn, address tokenOut)
        external
        view
        returns (uint256 amountFound, bool[] memory isConnected)
    {
        uint256 length = bridgeTokensIn.length;
        isConnected = new bool[](length);
        unchecked {
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < length; ++i) {
                if (
                    _isConnected({
                        isOriginSwap: false,
                        actionMask: bridgeTokensIn[i].actionMask,
                        tokenIn: bridgeTokensIn[i].token,
                        tokenOut: tokenOut
                    })
                ) {
                    isConnected[i] = true;
                    // unchecked: ++amountFound never overflows uint256
                    ++amountFound;
                }
            }
        }
    }

    /// @inheritdoc ISwapQuoterV1
    function getAmountOut(
        LimitedToken memory tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (SwapQuery memory query) {
        query = _getAmountOut(tokenIn.actionMask, tokenIn.token, tokenOut, amountIn);
        // tokenOut filed should always be populated, even if a path wasn't found
        query.tokenOut = tokenOut;
        // Fill the remaining fields if a path was found
        if (query.minAmountOut > 0) {
            // SynapseRouter should be used as "Router Adapter" for doing a swap through Default pools (or handling ETH),
            // as it inherits from DefaultAdapter.
            if (query.rawParams.length > 0) query.routerAdapter = synapseRouter;
            // Set default deadline to infinity. Not using the value of 0,
            // which would lead to every swap to revert by default.
            query.deadline = type(uint256).max;
        }
    }

    // ═════════════════════════════════════════════ GENERAL QUOTES V2 ═════════════════════════════════════════════════

    /// @inheritdoc ISwapQuoterV2
    function areConnectedTokens(LimitedToken memory tokenIn, address tokenOut) external view returns (bool) {
        // Check if this is a request for an origin swap.
        // These are given with the tokenIn.actionMask set to the full set of actions.
        bool isOriginSwap = tokenIn.actionMask == ActionLib.allActions();
        return _isConnected(isOriginSwap, tokenIn.actionMask, tokenIn.token, tokenOut);
    }

    // ══════════════════════════════════════════════ POOL GETTERS V1 ══════════════════════════════════════════════════

    /// @inheritdoc ISwapQuoterV1
    function allPools() external view returns (Pool[] memory pools) {
        // Combine Default, Linked, and Bridge pools into a single array
        uint256 amtOriginDefaultPools = _originDefaultPools.length();
        uint256 amtOriginLinkedPools = _originLinkedPools.length();
        uint256 amtBridgePools = _bridgeTokens.length();
        unchecked {
            // unchecked: total amount of pools never overflows uint256
            pools = new Pool[](amtOriginDefaultPools + amtOriginLinkedPools + amtBridgePools);
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < amtOriginDefaultPools; ++i) {
                pools[i] = _getPoolData(PoolType.Default, _originDefaultPools.at(i));
            }
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < amtOriginLinkedPools; ++i) {
                // unchecked: amtOriginDefaultPools + i < pools.length => never overflows
                pools[amtOriginDefaultPools + i] = _getPoolData(PoolType.Linked, _originLinkedPools.at(i));
            }
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < amtBridgePools; ++i) {
                address bridgeToken = _bridgeTokens.at(i);
                TypedPool memory typedPool = _bridgePools[bridgeToken];
                // unchecked: amtOriginDefaultPools + amtOriginLinkedPools + i < pools.length => never overflows uint256
                pools[amtOriginDefaultPools + amtOriginLinkedPools + i] = _getPoolData(
                    typedPool.poolType,
                    typedPool.pool
                );
            }
        }
    }

    /// @inheritdoc ISwapQuoterV1
    function poolsAmount() external view returns (uint256 amtPools) {
        // Total amount of pools is the sum of pools in each pool type and bridge pools
        unchecked {
            // unchecked: total amount of pools never overflows uint256
            return _originDefaultPools.length() + _originLinkedPools.length() + _bridgeTokens.length();
        }
    }

    // ═════════════════════════════════════════ INTERNAL: POOL MANAGEMENT ═════════════════════════════════════════════

    /// @dev Adds a pool to SwapQuoterV2.
    /// - If bridgeToken is zero, the pool is added to the set of pools corresponding to the pool type.
    /// - Otherwise, the pool is added to the set of bridge pools.
    function _addPool(BridgePool memory pool) internal {
        bool wasAdded = false;
        if (pool.bridgeToken == address(0)) {
            // No bridge token was supplied, so we add the pool to the corresponding set of "origin pools".
            // We also check that the pool has not been added yet.
            if (pool.poolType == PoolType.Default) {
                wasAdded = _originDefaultPools.add(pool.pool);
            } else {
                wasAdded = _originLinkedPools.add(pool.pool);
            }
        } else {
            address bridgeToken = pool.bridgeToken;
            // Bridge token was supplied, so we set the pool as the whitelisted pool for the bridge token.
            // We check that the old whitelisted pool is not the same as the new one.
            wasAdded = _bridgePools[bridgeToken].pool != pool.pool;
            // Add bridgeToken to the list of keys, if it wasn't added before
            _bridgeTokens.add(bridgeToken);
            _bridgePools[bridgeToken] = TypedPool({poolType: pool.poolType, pool: pool.pool});
        }
        if (!wasAdded) revert SwapQuoterV2__DuplicatedPool(pool.pool);
        emit PoolAdded(pool.bridgeToken, pool.poolType, pool.pool);
    }

    /// @dev Removes a pool from SwapQuoterV2.
    /// - If bridgeToken is zero, the pool is removed from the set of pools corresponding to the pool type.
    /// - Otherwise, the pool is removed from the set of bridge pools.
    function _removePool(BridgePool memory pool) internal {
        bool wasRemoved = false;
        if (pool.bridgeToken == address(0)) {
            // No bridge token was supplied, so we remove the pool from the corresponding set of "origin pools".
            // We also check that the pool has been added before.
            if (pool.poolType == PoolType.Default) {
                wasRemoved = _originDefaultPools.remove(pool.pool);
            } else {
                wasRemoved = _originLinkedPools.remove(pool.pool);
            }
        } else {
            address bridgeToken = pool.bridgeToken;
            // Bridge token was supplied, so we remove the pool as the whitelisted pool for the bridge token.
            // We check that the old whitelisted pool is the same as the one we want to remove.
            // Note: we remove both the pool (value) and the bridge token (key).
            wasRemoved = _bridgeTokens.remove(bridgeToken) && _bridgePools[bridgeToken].pool == pool.pool;
            delete _bridgePools[pool.bridgeToken];
        }
        if (!wasRemoved) revert SwapQuoterV2__UnknownPool(pool.pool);
        emit PoolRemoved(pool.bridgeToken, pool.poolType, pool.pool);
    }

    // ═════════════════════════════════════════ INTERNAL: POOL INSPECTION ═════════════════════════════════════════════

    /// @dev Returns the data for the given pool: pool address, LP token address (if applicable), and tokens.
    function _getPoolData(PoolType poolType, address pool) internal view returns (Pool memory poolData) {
        poolData.pool = pool;
        // Populate LP token field only for default pools
        if (poolType == PoolType.Default) poolData.lpToken = _lpToken(pool);
        poolData.tokens = _getPoolTokens(pool);
    }

    /// @dev Checks whether `tokenIn -> tokenOut` is possible given the `actionMask` of available actions for `tokenIn`.
    /// Will only consider the whitelisted pool for `tokenIn`, if Swap/AddLiquidity/RemoveLiquidity are required.
    function _isConnected(
        bool isOriginSwap,
        uint256 actionMask,
        address tokenIn,
        address tokenOut
    ) internal view returns (bool) {
        // If token addresses match, no action is required whatsoever.
        if (tokenIn == tokenOut) {
            return true;
        }
        // Check if ETH <> WETH (Action.HandleEth) could fulfill tokenIn -> tokenOut request.
        if (Action.HandleEth.isIncluded(actionMask) && _isEthAndWeth(tokenIn, tokenOut)) {
            return true;
        }
        if (isOriginSwap) {
            return _isOriginSwapPossible(actionMask, tokenIn, tokenOut);
        } else {
            return _isDestinationSwapPossible(actionMask, tokenIn, tokenOut);
        }
    }

    /// @dev Checks whether destination swap `tokenIn -> tokenOut` is possible:
    /// - Only whitelisted pool for `tokenIn` is considered.
    /// - Only pool-related actions included in `actionMask` are considered:
    ///     - Default Pool: Swap/AddLiquidity/RemoveLiquidity
    ///     - Linked Pool: Swap
    function _isDestinationSwapPossible(
        uint256 actionMask,
        address tokenIn,
        address tokenOut
    ) internal view returns (bool) {
        TypedPool memory bridgePool = _bridgePools[tokenIn];
        // Do nothing, if tokenIn doesn't have a whitelisted pool
        if (bridgePool.pool == address(0)) return false;
        if (bridgePool.poolType == PoolType.Default) {
            // Check if Default Pool could fulfill tokenIn -> tokenOut request.
            return _isConnectedViaDefaultPool(actionMask, bridgePool.pool, tokenIn, tokenOut);
        } else {
            // Check if Linked Pool could fulfill tokenIn -> tokenOut request.
            return _isConnectedViaLinkedPool(actionMask, bridgePool.pool, tokenIn, tokenOut);
        }
    }

    /// @dev Checks whether origin swap `tokenIn -> tokenOut` is possible:
    /// - All available pools are considered, both origin-only and whitelisted pools for destination swaps.
    /// - Only pool-related actions included in `actionMask` are considered:
    ///     - Default Pool: Swap/AddLiquidity/RemoveLiquidity
    ///     - Linked Pool: Swap
    function _isOriginSwapPossible(
        uint256 actionMask,
        address tokenIn,
        address tokenOut
    ) internal view returns (bool) {
        unchecked {
            uint256 numPools = _originDefaultPools.length();
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < numPools; ++i) {
                if (_isConnectedViaDefaultPool(actionMask, _originDefaultPools.at(i), tokenIn, tokenOut)) {
                    return true;
                }
            }
            numPools = _originLinkedPools.length();
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < numPools; ++i) {
                if (_isConnectedViaLinkedPool(actionMask, _originLinkedPools.at(i), tokenIn, tokenOut)) {
                    return true;
                }
            }
            // Also check all whitelisted pools for destination swaps, as these could be used for origin swaps as well
            numPools = _bridgeTokens.length();
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < numPools; ++i) {
                TypedPool memory bridgePool = _bridgePools[_bridgeTokens.at(i)];
                if (_isPoolSwapPossible(actionMask, bridgePool, tokenIn, tokenOut)) {
                    return true;
                }
            }
        }
        return false;
    }

    /// @dev Returns the SwapQuery struct that could be used to fulfill `tokenIn -> tokenOut` request.
    /// - Will check all liquidity pools, if `actionMask` is set to the full set of actions.
    /// - Will only check the whitelisted pool for `tokenIn` otherwise.
    /// > Only populates the `minAmountOut` and `rawParams` fields, unless no trade path is found between the tokens.
    /// > Other fields are supposed to be populated in the caller function.
    function _getAmountOut(
        uint256 actionMask,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (SwapQuery memory query) {
        // If token addresses match, no action is required whatsoever.
        if (tokenIn == tokenOut) {
            query.minAmountOut = amountIn;
            // query.rawParams is "", indicating that no further action is required
            return query;
        }
        // Note: we will be passing `quote` as a memory reference to the internal functions,
        // where it will be populated with the best quote found so far.
        // Check if ETH <> WETH (Action.HandleEth) could fulfill tokenIn -> tokenOut request.
        _checkHandleETHQuote(actionMask, tokenIn, tokenOut, amountIn, query);
        // Check if this is a request for an origin swap.
        // These are given with the tokenIn.actionMask set to the full set of actions.
        if (actionMask != ActionLib.allActions()) {
            // This is a request for a destination swap. Only whitelisted pool for `tokenIn` is considered.
            TypedPool memory bridgePool = _bridgePools[tokenIn];
            _checkPoolQuote(actionMask, bridgePool, tokenIn, tokenOut, amountIn, query);
            return query;
        }
        unchecked {
            // If this is a request for an origin swap, check all available origin-only pools
            uint256 numPools = _originDefaultPools.length();
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < numPools; ++i) {
                _checkDefaultPoolQuote(actionMask, _originDefaultPools.at(i), tokenIn, tokenOut, amountIn, query);
            }
            numPools = _originLinkedPools.length();
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < numPools; ++i) {
                _checkLinkedPoolQuote(actionMask, _originLinkedPools.at(i), tokenIn, tokenOut, amountIn, query);
            }
            // Also check all whitelisted pools for destination swaps, as these could be used for origin swaps as well
            numPools = _bridgeTokens.length();
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < numPools; ++i) {
                TypedPool memory bridgePool = _bridgePools[_bridgeTokens.at(i)];
                _checkPoolQuote(actionMask, bridgePool, tokenIn, tokenOut, amountIn, query);
            }
        }
    }

    /// @dev Checks whether `tokenIn -> tokenOut` is possible via the given Pool,
    /// given the `actionMask` of available actions for the token.
    /// Note: only checks pool-related actions:
    /// - Default Pool: Swap/AddLiquidity/RemoveLiquidity
    /// - Linked Pool: Swap
    function _isPoolSwapPossible(
        uint256 actionMask,
        TypedPool memory bridgePool,
        address tokenIn,
        address tokenOut
    ) internal view returns (bool) {
        // Don't do anything, if no whitelisted pool exists.
        if (bridgePool.pool == address(0)) return false;
        if (bridgePool.poolType == PoolType.Default) {
            return _isConnectedViaDefaultPool(actionMask, bridgePool.pool, tokenIn, tokenOut);
        } else {
            return _isConnectedViaLinkedPool(actionMask, bridgePool.pool, tokenIn, tokenOut);
        }
    }

    /// @dev Compares `curBestQuery` (representing query with the best quote found so far) with the quote for
    /// `tokenIn -> tokenOut` via the given Pool, given the `actionMask` of available actions for the token.
    /// If the action is possible, and the found quote is better, the `curBestQuote` is overwritten with
    /// the struct describing the new best quote.
    /// Note: `bridgePool` is a whitelisted liquidity pool for `tokenIn`, meaning that this is the only pool
    /// that could be used for "destination swaps" when bridging `tokenIn` to this chain.
    /// Note: only checks pool-related actions:
    /// - Default Pool: Swap/AddLiquidity/RemoveLiquidity
    /// - Linked Pool: Swap
    function _checkPoolQuote(
        uint256 actionMask,
        TypedPool memory bridgePool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        SwapQuery memory curBestQuery
    ) internal view {
        // Don't do anything, if no whitelisted pool exists.
        if (bridgePool.pool == address(0)) return;
        if (bridgePool.poolType == PoolType.Default) {
            _checkDefaultPoolQuote(actionMask, bridgePool.pool, tokenIn, tokenOut, amountIn, curBestQuery);
        } else {
            _checkLinkedPoolQuote(actionMask, bridgePool.pool, tokenIn, tokenOut, amountIn, curBestQuery);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IDefaultPoolCalc} from "../interfaces/IDefaultPoolCalc.sol";
import {IDefaultExtendedPool} from "../interfaces/IDefaultExtendedPool.sol";
import {ILinkedPool} from "../interfaces/ILinkedPool.sol";
import {IPausable} from "../interfaces/IPausable.sol";
import {ISwapQuoterV1, PoolToken, SwapQuery} from "../interfaces/ISwapQuoterV1.sol";
import {Action, DefaultParams} from "../libs/Structs.sol";
import {UniversalTokenLib} from "../libs/UniversalToken.sol";

/// @notice Stateless abstraction to calculate exact quotes for any DefaultPool instances.
abstract contract PoolQuoterV1 is ISwapQuoterV1 {
    /// @dev Returned index value for a token that is not found in the pool.
    /// We reasonably assume that no pool will ever hold 256 tokens, so this value is safe to use.
    uint8 private constant NOT_FOUND = 0xFF;

    /// @notice Address of deployed calculator contract for DefaultPool, which is able to calculate
    /// EXACT quotes for AddLiquidity action (something that DefaultPool contract itself is unable to do).
    address public immutable defaultPoolCalc;
    /// @notice Address of WETH token used in the pools. Represents wrapped version of chain's native currency,
    /// e.g. WETH on Ethereum, WBNB on BSC, etc.
    address public immutable weth;

    constructor(address defaultPoolCalc_, address weth_) {
        defaultPoolCalc = defaultPoolCalc_;
        weth = weth_;
    }

    // ═══════════════════════════════════════════ SPECIFIC POOL QUOTES ════════════════════════════════════════════════

    /// @inheritdoc ISwapQuoterV1
    function calculateAddLiquidity(address pool, uint256[] memory amounts) external view returns (uint256 amountOut) {
        // Forward the only getter that is not properly implemented in the StableSwap contract (DefaultPool).
        return IDefaultPoolCalc(defaultPoolCalc).calculateAddLiquidity(pool, amounts);
    }

    /// @inheritdoc ISwapQuoterV1
    function calculateSwap(
        address pool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256 amountOut) {
        return IDefaultExtendedPool(pool).calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
    }

    /// @inheritdoc ISwapQuoterV1
    function calculateRemoveLiquidity(address pool, uint256 amount)
        external
        view
        returns (uint256[] memory amountsOut)
    {
        return IDefaultExtendedPool(pool).calculateRemoveLiquidity(amount);
    }

    /// @inheritdoc ISwapQuoterV1
    function calculateWithdrawOneToken(
        address pool,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 amountOut) {
        return IDefaultExtendedPool(pool).calculateRemoveLiquidityOneToken(tokenAmount, tokenIndex);
    }

    // ══════════════════════════════════════════════ POOL GETTERS V1 ══════════════════════════════════════════════════

    /// @inheritdoc ISwapQuoterV1
    function poolInfo(address pool) external view returns (uint256 numTokens, address lpToken) {
        numTokens = _numTokens(pool);
        lpToken = _lpToken(pool);
    }

    /// @inheritdoc ISwapQuoterV1
    function poolTokens(address pool) external view returns (PoolToken[] memory tokens) {
        tokens = _getPoolTokens(pool);
    }

    // ══════════════════════════════════════════════ POOL INSPECTION ══════════════════════════════════════════════════

    /// @dev Returns the LP token address for the given pool, if it exists. Otherwise, returns address(0).
    function _lpToken(address pool) internal view returns (address) {
        // Try getting the LP token address from the pool.
        try IDefaultExtendedPool(pool).swapStorage() returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address lpToken
        ) {
            return lpToken;
        } catch {
            // Return address(0) if the pool doesn't have an LP token.
            return address(0);
        }
    }

    /// @dev Returns the number of tokens the given pool supports.
    function _numTokens(address pool) internal view returns (uint256 numTokens) {
        while (true) {
            // Iterate over the tokens until we get an exception.
            try IDefaultExtendedPool(pool).getToken(uint8(numTokens)) returns (address) {
                unchecked {
                    // unchecked: ++numTokens never overflows uint256
                    ++numTokens;
                }
            } catch {
                // End of pool reached, exit the loop.
                break;
            }
        }
    }

    /// @dev Returns the tokens the given pool supports.
    function _getPoolTokens(address pool) internal view returns (PoolToken[] memory tokens) {
        uint256 numTokens = _numTokens(pool);
        tokens = new PoolToken[](numTokens);
        unchecked {
            // unchecked: ++i never overflows uint256
            for (uint256 i = 0; i < numTokens; ++i) {
                address token = IDefaultExtendedPool(pool).getToken(uint8(i));
                tokens[i] = PoolToken({isWeth: token == weth, token: token});
            }
        }
    }

    /// @dev Returns pool indexes for the two given tokens.
    /// - The return value NOT_FOUND (0xFF) means a token is not supported by the pool.
    /// - If one of the pool tokens is WETH, ETH_ADDRESS is also considered as a pool token: a valid index
    /// representing WETH in returned.
    /// Note: this is not supposed to be used with LinkedPool contracts, as a single token can appear
    /// multiple times in the LinkedPool's token tree.
    function _getTokenIndexes(
        address pool,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint8 indexIn, uint8 indexOut) {
        uint256 numTokens = _numTokens(pool);
        // Assign NOT_FOUND to both indexes by default. This value will be overwritten if the token is found.
        indexIn = NOT_FOUND;
        indexOut = NOT_FOUND;
        unchecked {
            // unchecked: numTokens <= 255 => ++t never overflows uint8
            for (uint8 t = 0; t < numTokens; ++t) {
                address poolToken = IDefaultExtendedPool(pool).getToken(t);
                if (_poolToken(tokenIn) == poolToken) indexIn = t;
                if (_poolToken(tokenOut) == poolToken) indexOut = t;
            }
        }
    }

    /// @dev Checks if a pool conforms to IPausable interface, and if so, returns its paused state.
    /// Returns false if pool does not conform to IPausable interface.
    function _isPoolPaused(address pool) internal view returns (bool) {
        // We issue a static call in case the pool does not conform to IPausable interface.
        (bool success, bytes memory returnData) = pool.staticcall(abi.encodeWithSelector(IPausable.paused.selector));
        // Pool is paused if the call was successful and returned true.
        // We check the return data length to ensure abi.decode won't revert.
        return success && returnData.length == 32 && abi.decode(returnData, (bool));
    }

    // ════════════════════════════════════════ POOL TOKEN -> TOKEN QUOTES ═════════════════════════════════════════════

    /// @dev Checks whether `tokenIn -> tokenOut` is possible via the given Default Pool, given the
    /// `actionMask` of available actions for the token.
    /// Note: only checks DefaultPool-related actions: Swap/AddLiquidity/RemoveLiquidity.
    function _isConnectedViaDefaultPool(
        uint256 actionMask,
        address pool,
        address tokenIn,
        address tokenOut
    ) internal view returns (bool) {
        // We don't check for paused pools here, as we only need to know if a connection exists.
        (uint8 indexIn, uint8 indexOut) = _getTokenIndexes(pool, tokenIn, tokenOut);
        // Check if Swap (tokenIn -> tokenOut) could fulfill tokenIn -> tokenOut request.
        if (Action.Swap.isIncluded(actionMask) && indexIn != NOT_FOUND && indexOut != NOT_FOUND) {
            return true;
        }
        address lpToken = _lpToken(pool);
        // Check if AddLiquidity (tokenIn -> lpToken) could fulfill tokenIn -> tokenOut request.
        if (Action.AddLiquidity.isIncluded(actionMask) && indexIn != NOT_FOUND && tokenOut == lpToken) {
            return true;
        }
        // Check if RemoveLiquidity (lpToken -> tokenOut) could fulfill tokenIn -> tokenOut request.
        if (Action.RemoveLiquidity.isIncluded(actionMask) && tokenIn == lpToken && indexOut != NOT_FOUND) {
            return true;
        }
        return false;
    }

    /// @dev Checks whether `tokenIn -> tokenOut` is possible via the given Linked Pool, given the
    /// `actionMask` of available actions for the token.
    /// Note: only checks LinkedPool-related actions: Swap.
    function _isConnectedViaLinkedPool(
        uint256 actionMask,
        address pool,
        address tokenIn,
        address tokenOut
    ) internal view returns (bool) {
        // Check if Swap (tokenIn -> tokenOut) could fulfill tokenIn -> tokenOut request.
        if (Action.Swap.isIncluded(actionMask)) {
            // Check if tokenIn and tokenOut are connected via the LinkedPool.
            // We are converting ETH -> WETH here, as LinkedPool is unaware of ETH.
            return ILinkedPool(pool).areConnectedTokens(_poolToken(tokenIn), _poolToken(tokenOut));
        }
        return false;
    }

    /// @dev Compares `curBestQuery` (representing query with the best quote found so far) with the quote for
    /// `tokenIn -> tokenOut` via the given Default Pool, given the `actionMask` of available actions for the token.
    /// If the action is possible, and the found quote is better, the `curBestQuote` is overwritten with
    /// the struct describing the new best quote.
    /// Note: only checks pool-related actions: Swap/AddLiquidity/RemoveLiquidity.
    /// Note: this is not supposed to be used with LinkedPool contracts, as a single token can appear
    /// multiple times in the LinkedPool's token tree.
    function _checkDefaultPoolQuote(
        uint256 actionMask,
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        SwapQuery memory curBestQuery
    ) internal view {
        // Skip paused pools
        if (_isPoolPaused(pool)) return;
        // Check if tokenIn and tokenOut are pool tokens
        (uint8 indexIn, uint8 indexOut) = _getTokenIndexes(pool, tokenIn, tokenOut);
        if (indexIn != NOT_FOUND && indexOut != NOT_FOUND) {
            // tokenIn, tokenOut are pool tokens: Action.Swap is required
            _checkSwapQuote(actionMask, pool, indexIn, indexOut, amountIn, curBestQuery);
            return;
        }
        address lpToken = _lpToken(pool);
        if (indexIn != NOT_FOUND && tokenOut == lpToken) {
            // tokenIn is pool token, tokenOut is LP token: Action.AddLiquidity is required
            _checkAddLiquidityQuote(actionMask, pool, indexIn, amountIn, curBestQuery);
        } else if (tokenIn == lpToken && indexOut != NOT_FOUND) {
            // tokenIn is LP token, tokenOut is pool token: Action.RemoveLiquidity is required
            _checkRemoveLiquidityQuote(actionMask, pool, indexOut, amountIn, curBestQuery);
        }
    }

    /// @dev Compares `curBestQuery` (representing query with the best quote found so far) with the quote for
    /// `tokenIn -> tokenOut` via the given Linked Pool, given the `actionMask` of available actions for the token.
    /// If the action is possible, and the found quote is better, the `curBestQuote` is overwritten with
    /// the struct describing the new best quote.
    /// Note: only checks pool-related actions: Swap.
    function _checkLinkedPoolQuote(
        uint256 actionMask,
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        SwapQuery memory curBestQuery
    ) internal view {
        // Only Swap action is supported for LinkedPools
        if (Action.Swap.isIncluded(actionMask)) {
            // Find the best quote that LinkedPool can offer
            // We are converting ETH -> WETH here, as LinkedPool is unaware of ETH.
            try ILinkedPool(pool).findBestPath(_poolToken(tokenIn), _poolToken(tokenOut), amountIn) returns (
                uint8 tokenIndexFrom,
                uint8 tokenIndexTo,
                uint256 amountOut
            ) {
                // Update the current quote if the new quote is better
                if (amountOut > curBestQuery.minAmountOut) {
                    curBestQuery.minAmountOut = amountOut;
                    // Encode params for swapping via the current pool: specify indexFrom and indexTo
                    curBestQuery.rawParams = abi.encode(DefaultParams(Action.Swap, pool, tokenIndexFrom, tokenIndexTo));
                }
            } catch {
                // solhint-disable-previous-line no-empty-blocks
                // Do nothing, if the quote fails
            }
        }
    }

    // ════════════════════════════════════════ POOL INDEX -> INDEX QUOTES ═════════════════════════════════════════════

    /// @dev Compares `curBestQuery` (representing query with the best quote found so far) with the quote for
    /// `tokenIn -> tokenOut` via the given Default Pool, only considering Swap action.
    /// If the action is possible, and the found quote is better, the `curBestQuote` is overwritten with
    /// the struct describing the new best quote.
    /// - tokenIn -> tokenOut swap will be considered.
    /// - Won't do anything if Action.Swap is not included in `actionMask`.
    function _checkSwapQuote(
        uint256 actionMask,
        address pool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 amountIn,
        SwapQuery memory curBestQuery
    ) internal view {
        // Don't do anything if we haven't specified Swap as possible action
        if (!Action.Swap.isIncluded(actionMask)) return;
        try IDefaultExtendedPool(pool).calculateSwap(tokenIndexFrom, tokenIndexTo, amountIn) returns (
            uint256 amountOut
        ) {
            if (amountOut > curBestQuery.minAmountOut) {
                curBestQuery.minAmountOut = amountOut;
                // Encode params for swapping via the current pool: specify indexFrom and indexTo
                curBestQuery.rawParams = abi.encode(DefaultParams(Action.Swap, pool, tokenIndexFrom, tokenIndexTo));
            }
        } catch {
            // solhint-disable-previous-line no-empty-blocks
            // If swap quote fails, we just ignore it
        }
    }

    /// @dev Compares `curBestQuery` (representing query with the best quote found so far) with the quote for
    /// `tokenIn -> tokenOut` via the given Default Pool, only considering AddLiquidity action.
    /// If the action is possible, and the found quote is better, the `curBestQuote` is overwritten with
    /// the struct describing the new best quote.
    /// - This is the equivalent of tokenIn -> LPToken swap.
    /// - Won't do anything if Action.AddLiquidity is not included in `actionMask`.
    function _checkAddLiquidityQuote(
        uint256 actionMask,
        address pool,
        uint8 tokenIndexFrom,
        uint256 amountIn,
        SwapQuery memory curBestQuery
    ) internal view {
        // Don't do anything if we haven't specified AddLiquidity as possible action
        if (!Action.AddLiquidity.isIncluded(actionMask)) return;
        uint256[] memory amounts = new uint256[](_numTokens(pool));
        amounts[tokenIndexFrom] = amountIn;
        // Use DefaultPool Calc as we need the EXACT quote here
        try IDefaultPoolCalc(defaultPoolCalc).calculateAddLiquidity(pool, amounts) returns (uint256 amountOut) {
            if (amountOut > curBestQuery.minAmountOut) {
                curBestQuery.minAmountOut = amountOut;
                // Encode params for adding liquidity via the current pool: specify indexFrom (indexTo = 0xFF)
                curBestQuery.rawParams = abi.encode(
                    DefaultParams(Action.AddLiquidity, pool, tokenIndexFrom, type(uint8).max)
                );
            }
        } catch {
            // solhint-disable-previous-line no-empty-blocks
            // If addLiquidity quote fails, we just ignore it
        }
    }

    /// @dev Compares `curBestQuery` (representing query with the best quote found so far) with the quote for
    /// `tokenIn -> tokenOut` via the given Default Pool, only considering RemoveLiquidity action.
    /// If the action is possible, and the found quote is better, the `curBestQuote` is overwritten with
    /// the struct describing the new best quote.
    /// - This is the equivalent of LPToken -> tokenOut swap.
    /// - Won't do anything if Action.RemoveLiquidity is not included in `actionMask`.
    function _checkRemoveLiquidityQuote(
        uint256 actionMask,
        address pool,
        uint8 tokenIndexTo,
        uint256 amountIn,
        SwapQuery memory curBestQuery
    ) internal view {
        // Don't do anything if we haven't specified RemoveLiquidity as possible action
        if (!Action.RemoveLiquidity.isIncluded(actionMask)) return;
        try IDefaultExtendedPool(pool).calculateRemoveLiquidityOneToken(amountIn, tokenIndexTo) returns (
            uint256 amountOut
        ) {
            if (amountOut > curBestQuery.minAmountOut) {
                curBestQuery.minAmountOut = amountOut;
                // Encode params for removing liquidity via the current pool: specify indexTo (indexFrom = 0xFF)
                curBestQuery.rawParams = abi.encode(
                    DefaultParams(Action.RemoveLiquidity, pool, type(uint8).max, tokenIndexTo)
                );
            }
        } catch {
            // solhint-disable-previous-line no-empty-blocks
            // If removeLiquidity quote fails, we just ignore it
        }
    }

    /// @dev Compares `curBestQuery` (representing query with the best quote found so far) with the quote for
    /// `tokenIn -> tokenOut` only considering HandleEth action.
    /// If the action is possible, and the found quote is better, the `curBestQuote` is overwritten with
    /// the struct describing the new best quote.
    /// - That would be either unwrapping WETH into native ETH, or wrapping ETH into WETH.
    /// - Won't do anything if Action.HandleEth is not included in `actionMask`.
    function _checkHandleETHQuote(
        uint256 actionMask,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        SwapQuery memory curBestQuery
    ) internal view {
        // Don't do anything if we haven't specified HandleETH as possible action
        if (!Action.HandleEth.isIncluded(actionMask)) return;
        if (_isEthAndWeth(tokenIn, tokenOut) && amountIn > curBestQuery.minAmountOut) {
            curBestQuery.minAmountOut = amountIn;
            // Encode params for handling ETH: no pool is present, indexFrom and indexTo are 0xFF
            curBestQuery.rawParams = abi.encode(
                DefaultParams(Action.HandleEth, address(0), type(uint8).max, type(uint8).max)
            );
        }
    }

    // ═════════════════════════════════════════ INTERNAL UTILS: ETH, WETH ═════════════════════════════════════════════

    /// @dev Checks that (tokenA, tokenB) is either (ETH, WETH) or (WETH, ETH).
    function _isEthAndWeth(address tokenA, address tokenB) internal view returns (bool) {
        return
            (tokenA == UniversalTokenLib.ETH_ADDRESS && tokenB == weth) ||
            (tokenA == weth && tokenB == UniversalTokenLib.ETH_ADDRESS);
    }

    /// @dev Returns token address used in the pool for the given "underlying token".
    /// This is either the token itself, or WETH if the token is ETH.
    function _poolToken(address token) internal view returns (address) {
        return token == UniversalTokenLib.ETH_ADDRESS ? weth : token;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LimitedToken, SwapQuery, Pool, PoolToken} from "../libs/Structs.sol";

/// @notice Interface for the SwapQuoterV1 version with updated pragma and enriched docs.
interface ISwapQuoterV1 {
    // ════════════════════════════════════════════════ IMMUTABLES ════════════════════════════════════════════════════

    /// @notice Address of deployed calculator contract for DefaultPool, which is able to calculate
    /// EXACT quotes for AddLiquidity action (something that DefaultPool contract itself is unable to do).
    function defaultPoolCalc() external view returns (address);

    /// @notice Address of WETH token used in the pools. Represents wrapped version of chain's native currency,
    /// e.g. WETH on Ethereum, WBNB on BSC, etc.
    function weth() external view returns (address);

    // ═══════════════════════════════════════════════ POOL GETTERS ════════════════════════════════════════════════════

    /// @notice Returns a list of all supported pools.
    function allPools() external view returns (Pool[] memory pools);

    /// @notice Returns the amount of supported pools.
    function poolsAmount() external view returns (uint256 amtPools);

    /// @notice Returns the number of tokens the given pool supports and the pool's LP token.
    function poolInfo(address pool) external view returns (uint256 numTokens, address lpToken);

    /// @notice Returns a list of pool tokens for the given pool.
    function poolTokens(address pool) external view returns (PoolToken[] memory tokens);

    // ══════════════════════════════════════════════ GENERAL QUOTES ═══════════════════════════════════════════════════

    /// @notice Checks if a swap is possible between every bridge token in the given list and tokenOut.
    /// Only the bridge token's whitelisted pool is considered for every `tokenIn -> tokenOut` swap.
    /// @param bridgeTokensIn   List of structs with following information:
    ///                         - actionMask    Bitmask of available actions for doing tokenIn -> tokenOut
    ///                         - token         Bridge token address to swap from
    /// @param tokenOut         Token address to swap to
    /// @return amountFound     Amount of tokens from the list that are swappable to tokenOut
    /// @return isConnected     List of bool values, specifying whether a token from the list is swappable to tokenOut
    function findConnectedTokens(LimitedToken[] memory bridgeTokensIn, address tokenOut)
        external
        view
        returns (uint256 amountFound, bool[] memory isConnected);

    /// @notice Finds the quote and the swap parameters for a tokenIn -> tokenOut swap from the list of supported pools.
    /// - If this is a request for the swap to be performed immediately (or the "origin swap" in the bridge workflow),
    /// `tokenIn.actionMask` needs to be set to bitmask of all possible actions (ActionLib.allActions()).
    /// - If this is a request for the swap to be performed as the "destination swap" in the bridge workflow,
    /// `tokenIn.actionMask` needs to be set to bitmask of possible actions for `tokenIn.token` as a bridge token,
    /// e.g. Action.Swap for minted tokens, or Action.RemoveLiquidity | Action.HandleEth for withdrawn tokens.
    /// > Returns the `SwapQuery` struct, that can be used on SynapseRouter.
    /// > minAmountOut and deadline fields will need to be adjusted based on the swap settings.
    /// @dev If tokenIn or tokenOut is ETH_ADDRESS, only the pools having WETH as a pool token will be considered.
    /// Three potential outcomes are available:
    /// 1. `tokenIn` and `tokenOut` represent the same token address (identical tokens).
    /// 2. `tokenIn` and `tokenOut` represent different addresses. No trade path from `tokenIn` to `tokenOut` is found.
    /// 3. `tokenIn` and `tokenOut` represent different addresses. Trade path from `tokenIn` to `tokenOut` is found.
    /// The exact composition of the returned struct for every case is documented in the return parameter documentation.
    /// @param tokenIn  Struct with following information:
    ///                 - actionMask    Bitmask of available actions for doing tokenIn -> tokenOut
    ///                 - token         Token address to swap from
    /// @param tokenOut Token address to swap to
    /// @param amountIn Amount of tokens to swap from
    /// @return query   Struct representing trade path between tokenIn and tokenOut:
    ///                 - swapAdapter: adapter address that would handle the swap. Address(0) if no path is found,
    ///                 or tokens are identical. Address of SynapseRouter otherwise.
    ///                 - tokenOut: always equals to the provided `tokenOut`, even if no path if found.
    ///                 - minAmountOut: amount of `tokenOut`, if swap was completed now. 0, if no path is found.
    ///                 - deadline: 2**256-1 if path was found, or tokens are identical. 0, if no path is found.
    ///                 - rawParams: ABI-encoded DefaultParams struct indicating the swap parameters. Empty string,
    ///                 if no path is found, or tokens are identical.
    function getAmountOut(
        LimitedToken memory tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (SwapQuery memory query);

    // ═══════════════════════════════════════════ SPECIFIC POOL QUOTES ════════════════════════════════════════════════

    /// @notice Returns the exact quote for adding liquidity to a given pool in a form of a single token.
    /// @dev The only way to get a quote for adding liquidity would be `pool.calculateTokenAmount()`,
    /// which gives an ESTIMATE: it doesn't take the trade fees into account.
    /// We do need the exact quotes for (DAI/USDC/USDT) -> nUSD "swaps" on Mainnet, hence we do this.
    /// We also need the exact quotes for adding liquidity to the pools.
    /// Note: the function might revert instead of returning 0 for incorrect requests. Make sure
    /// to take that into account.
    function calculateAddLiquidity(address pool, uint256[] memory amounts) external view returns (uint256 amountOut);

    /// @notice Returns the exact quote for swapping between two given tokens.
    /// @dev Exposes IDefaultPool.calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
    function calculateSwap(
        address pool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256 amountOut);

    /// @notice Returns the exact quote for withdrawing pools tokens in a balanced way.
    /// @dev Exposes IDefaultPool.calculateRemoveLiquidity(amount);
    function calculateRemoveLiquidity(address pool, uint256 amount) external view returns (uint256[] memory amountsOut);

    /// @notice Returns the exact quote for withdrawing a single pool token.
    /// @dev Exposes IDefaultPool.calculateRemoveLiquidityOneToken(tokenAmount, tokenIndex);
    function calculateWithdrawOneToken(
        address pool,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISwapQuoterV1} from "./ISwapQuoterV1.sol";
import {LimitedToken} from "../libs/Structs.sol";

interface ISwapQuoterV2 is ISwapQuoterV1 {
    /// @notice Checks if tokenIn -> tokenOut swap is possible using the supported pools.
    /// Follows `getAmountOut()` convention when it comes to providing tokenIn.actionMask:
    /// - If this is a request for the swap to be performed immediately (or the "origin swap" in the bridge workflow),
    /// `tokenIn.actionMask` needs to be set to bitmask of all possible actions (ActionLib.allActions()).
    ///  For this case, all pools added to SwapQuoterV2 will be considered for the swap.
    /// - If this is a request for the swap to be performed as the "destination swap" in the bridge workflow,
    /// `tokenIn.actionMask` needs to be set to bitmask of possible actions for `tokenIn.token` as a bridge token,
    /// e.g. Action.Swap for minted tokens, or Action.RemoveLiquidity | Action.HandleEth for withdrawn tokens.
    ///
    /// As for the pools considered for the swap, there are two cases:
    /// - If this is a request for the swap to be performed immediately (or the "origin swap" in the bridge workflow),
    /// all pools added to SwapQuoterV2 will be considered for the swap.
    /// - If this is a request for the swap to be performed as the "destination swap" in the bridge workflow,
    /// only the whitelisted pool for tokenIn.token will be considered for the swap.
    function areConnectedTokens(LimitedToken memory tokenIn, address tokenOut) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13; // "using A for B global" requires 0.8.13 or higher

// ══════════════════════════════════════════ TOKEN AND POOL DESCRIPTION ═══════════════════════════════════════════════

/// @notice Struct representing a bridge token. Used as the return value in view functions.
/// @param symbol   Bridge token symbol: unique token ID consistent among all chains
/// @param token    Bridge token address
struct BridgeToken {
    string symbol;
    address token;
}

/// @notice Struct used by IPoolHandler to represent a token in a pool
/// @param index    Token index in the pool
/// @param token    Token address
struct IndexedToken {
    uint8 index;
    address token;
}

/// @notice Struct representing a token, and the available Actions for performing a swap.
/// @param actionMask   Bitmask representing what actions (see ActionLib) are available for swapping a token
/// @param token        Token address
struct LimitedToken {
    uint256 actionMask;
    address token;
}

/// @notice Struct representing how pool tokens are stored by `SwapQuoter`.
/// @param isWeth   Whether the token represents Wrapped ETH.
/// @param token    Token address.
struct PoolToken {
    bool isWeth;
    address token;
}

/// @notice Struct representing a liquidity pool. Used as the return value in view functions.
/// @param pool         Pool address.
/// @param lpToken      Address of pool's LP token.
/// @param tokens       List of pool's tokens.
struct Pool {
    address pool;
    address lpToken;
    PoolToken[] tokens;
}

// ════════════════════════════════════════════════ ROUTER STRUCTS ═════════════════════════════════════════════════════

/// @notice Struct representing a quote request for swapping a bridge token.
/// Used in destination chain's SynapseRouter, hence the name "Destination Request".
/// @dev tokenOut is passed externally.
/// @param symbol   Bridge token symbol: unique token ID consistent among all chains
/// @param amountIn Amount of bridge token to start with, before the bridge fee is applied
struct DestRequest {
    string symbol;
    uint256 amountIn;
}

/// @notice Struct representing a swap request for SynapseRouter.
/// @dev tokenIn is supplied separately.
/// @param routerAdapter    Contract that will perform the swap for the Router. Address(0) specifies a "no swap" query.
/// @param tokenOut         Token address to swap to.
/// @param minAmountOut     Minimum amount of tokens to receive after the swap, or tx will be reverted.
/// @param deadline         Latest timestamp for when the transaction needs to be executed, or tx will be reverted.
/// @param rawParams        ABI-encoded params for the swap that will be passed to `routerAdapter`.
///                         Should be DefaultParams for swaps via DefaultAdapter.
struct SwapQuery {
    address routerAdapter;
    address tokenOut;
    uint256 minAmountOut;
    uint256 deadline;
    bytes rawParams;
}

using SwapQueryLib for SwapQuery global;

library SwapQueryLib {
    /// @notice Checks whether the router adapter was specified in the query.
    /// Query without a router adapter specifies that no action needs to be taken.
    function hasAdapter(SwapQuery memory query) internal pure returns (bool) {
        return query.routerAdapter != address(0);
    }

    /// @notice Fills `routerAdapter` and `deadline` fields in query, if it specifies one of the supported Actions,
    /// and if a path for this action was found.
    function fillAdapterAndDeadline(SwapQuery memory query, address routerAdapter) internal pure {
        // Fill the fields only if some path was found.
        if (query.minAmountOut == 0) return;
        // Empty params indicates no action needs to be done, thus no adapter is needed.
        query.routerAdapter = query.rawParams.length == 0 ? address(0) : routerAdapter;
        // Set default deadline to infinity. Not using the value of 0,
        // which would lead to every swap to revert by default.
        query.deadline = type(uint256).max;
    }
}

// ════════════════════════════════════════════════ ADAPTER STRUCTS ════════════════════════════════════════════════════

/// @notice Struct representing parameters for swapping via DefaultAdapter.
/// @param action           Action that DefaultAdapter needs to perform.
/// @param pool             Liquidity pool that will be used for Swap/AddLiquidity/RemoveLiquidity actions.
/// @param tokenIndexFrom   Token index to swap from. Used for swap/addLiquidity actions.
/// @param tokenIndexTo     Token index to swap to. Used for swap/removeLiquidity actions.
struct DefaultParams {
    Action action;
    address pool;
    uint8 tokenIndexFrom;
    uint8 tokenIndexTo;
}

/// @notice All possible actions that DefaultAdapter could perform.
enum Action {
    Swap, // swap between two pools tokens
    AddLiquidity, // add liquidity in a form of a single pool token
    RemoveLiquidity, // remove liquidity in a form of a single pool token
    HandleEth // ETH <> WETH interaction
}

using ActionLib for Action global;

/// @notice Library for dealing with bit masks which describe what set of Actions is available.
library ActionLib {
    /// @notice Returns a bitmask with all possible actions set to True.
    function allActions() internal pure returns (uint256 actionMask) {
        actionMask = type(uint256).max;
    }

    /// @notice Returns whether the given action is set to True in the bitmask.
    function isIncluded(Action action, uint256 actionMask) internal pure returns (bool) {
        return actionMask & mask(action) != 0;
    }

    /// @notice Returns a bitmask with only the given action set to True.
    function mask(Action action) internal pure returns (uint256) {
        return 1 << uint256(action);
    }

    /// @notice Returns a bitmask with only two given actions set to True.
    function mask(Action a, Action b) internal pure returns (uint256) {
        return mask(a) | mask(b);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
pragma solidity 0.8.17;

interface IDefaultPoolCalc {
    /// @notice Calculates the EXACT amount of LP tokens received for a given amount of tokens deposited
    /// into a DefaultPool.
    /// @param pool         Address of the DefaultPool.
    /// @param amounts      Amounts of tokens to deposit.
    /// @return amountOut   Amount of LP tokens received.
    function calculateAddLiquidity(address pool, uint256[] memory amounts) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IDefaultPool} from "./IDefaultPool.sol";

interface IDefaultExtendedPool is IDefaultPool {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
        external
        view
        returns (uint256 availableTokenAmount);

    function getAPrecise() external view returns (uint256);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function swapStorage()
        external
        view
        returns (
            uint256 initialA,
            uint256 futureA,
            uint256 initialATime,
            uint256 futureATime,
            uint256 swapFee,
            uint256 adminFee,
            address lpToken
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILinkedPool {
    /// @notice Wrapper for IDefaultPool.swap()
    /// @param tokenIndexFrom    the token the user wants to swap from
    /// @param tokenIndexTo      the token the user wants to swap to
    /// @param dx                the amount of tokens the user wants to swap from
    /// @param minDy             the min amount the user would like to receive, or revert.
    /// @param deadline          latest timestamp to accept this transaction
    /// @return amountOut        amount of tokens bought
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256 amountOut);

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /// @notice Wrapper for IDefaultPool.calculateSwap()
    /// @param tokenIndexFrom    the token the user wants to sell
    /// @param tokenIndexTo      the token the user wants to buy
    /// @param dx                the amount of tokens the user wants to sell. If the token charges
    ///                          a fee on transfers, use the amount that gets transferred after the fee.
    /// @return amountOut        amount of tokens the user will receive
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256 amountOut);

    /// @notice Wrapper for IDefaultPool.getToken()
    /// @param index     the index of the token
    /// @return token    address of the token at given index
    function getToken(uint8 index) external view returns (address token);

    /// @notice Checks if a path exists between the two tokens, using any of the supported pools.
    /// @dev This is used by SwapQuoterV2 to check if a path exists between two tokens using the LinkedPool.
    /// Note: this only checks if both tokens are present in the tree, but doesn't check if any of the pools
    /// connecting the two tokens are paused. This is done to enable caching of the result, the paused/duplicated
    /// pools will be discarded, when `findBestPath` is called to fetch the quote.
    /// @param tokenIn          Token address to begin from
    /// @param tokenOut         Token address to end up with
    /// @return areConnected    True if a path exists between the two tokens, false otherwise
    function areConnectedTokens(address tokenIn, address tokenOut) external view returns (bool areConnected);

    /// @notice Returns the best path for swapping the given amount of tokens. All possible paths
    /// present in the internal tree are considered, if any of the tokens are present in the tree more than once.
    /// Note: paths that have the same pool more than once are not considered.
    /// @dev Will return zero values if no path is found.
    /// @param tokenIn          the token the user wants to sell
    /// @param tokenOut         the token the user wants to buy
    /// @param amountIn         the amount of tokens the user wants to sell
    /// @return tokenIndexFrom  the index of the token the user wants to sell
    /// @return tokenIndexTo    the index of the token the user wants to buy
    /// @return amountOut       amount of tokens the user will receive
    function findBestPath(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    )
        external
        view
        returns (
            uint8 tokenIndexFrom,
            uint8 tokenIndexTo,
            uint256 amountOut
        );

    /// @notice Returns the full amount of the "token nodes" in the internal tree.
    /// Note that some of the tokens might be duplicated, as the node in the tree represents
    /// a given path frm the bridge token to the node token using a series of pools.
    function tokenNodesAmount() external view returns (uint256);

    /// @notice Returns the list of pools that are "attached" to a node.
    /// Pool is attached to a node, if it connects the node to one of its children.
    /// Note: pool that is connecting the node to its parent is not considered attached.
    function getAttachedPools(uint8 index) external view returns (address[] memory pools);

    /// @notice Returns the list of indexes that represent a given token in the tree.
    /// @dev Will return empty array for tokens that are not added to the tree.
    function getTokenIndexes(address token) external view returns (uint256[] memory indexes);

    /// @notice Returns the pool module logic address, that is used to get swap quotes, token indexes and perform swaps.
    /// @dev Will return address(0) for pools that are not added to the tree.
    /// Will return address(this) for pools that conform to IDefaultPool interface.
    function getPoolModule(address pool) external view returns (address poolModule);

    /// @notice Returns the index of a parent node for the given node, as well as the pool that connects the two nodes.
    /// @dev Will return zero values for the root node. Will revert if index is out of range.
    function getNodeParent(uint256 nodeIndex) external view returns (uint256 parentIndex, address parentPool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPausable {
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenNotContract} from "./Errors.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts-4.5.0/token/ERC20/utils/SafeERC20.sol";

library UniversalTokenLib {
    using SafeERC20 for IERC20;

    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Transfers tokens to the given account. Reverts if transfer is not successful.
    /// @dev This might trigger fallback, if ETH is transferred to the contract.
    /// Make sure this can not lead to reentrancy attacks.
    function universalTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // Don't do anything, if need to send tokens to this address
        if (to == address(this)) return;
        if (token == ETH_ADDRESS) {
            /// @dev Note: this can potentially lead to executing code in `to`.
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = to.call{value: value}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(token).safeTransfer(to, value);
        }
    }

    /// @notice Issues an infinite allowance to the spender, if the current allowance is insufficient
    /// to spend the given amount.
    function universalApproveInfinity(
        address token,
        address spender,
        uint256 amountToSpend
    ) internal {
        // ETH Chad doesn't require your approval
        if (token == ETH_ADDRESS) return;
        // No-op if allowance is already sufficient
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance >= amountToSpend) return;
        // Otherwise, reset approval to 0 and set to max allowance
        if (allowance > 0) IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, type(uint256).max);
    }

    /// @notice Returns the balance of the given token (or native ETH) for the given account.
    function universalBalanceOf(address token, address account) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    /// @dev Checks that token is a contract and not ETH_ADDRESS.
    function assertIsContract(address token) internal view {
        // Check that ETH_ADDRESS was not used (in case this is a predeploy on any of the chains)
        if (token == UniversalTokenLib.ETH_ADDRESS) revert TokenNotContract();
        // Check that token is not an EOA
        if (token.code.length == 0) revert TokenNotContract();
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDefaultPool {
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256 amountOut);

    function getToken(uint8 index) external view returns (address token);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error DeadlineExceeded();
error InsufficientOutputAmount();

error MsgValueIncorrect();
error PoolNotFound();
error TokenAddressMismatch();
error TokenNotContract();
error TokenNotETH();
error TokensIdentical();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}