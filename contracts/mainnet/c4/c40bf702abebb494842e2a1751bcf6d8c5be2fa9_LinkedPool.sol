// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IPausable} from "./interfaces/IPausable.sol";
import {IndexedToken, IPoolModule} from "./interfaces/IPoolModule.sol";
import {ILinkedPool} from "./interfaces/ILinkedPool.sol";
import {IDefaultPool} from "./interfaces/IDefaultPool.sol";
import {Action} from "./libs/Structs.sol";
import {UniversalTokenLib} from "./libs/UniversalToken.sol";
import {TokenTree} from "./tree/TokenTree.sol";

import {Ownable} from "@openzeppelin/contracts-4.5.0/access/Ownable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts-4.5.0/token/ERC20/utils/SafeERC20.sol";

/// LinkedPool is using an internal Token Tree to aggregate a collection of pools with correlated
/// tokens into a single wrapper, conforming to IDefaultPool interface.
/// The internal Token Tree allows to store up to 256 tokens, which should be enough for most use cases.
/// Note: unlike traditional Default pools, tokens in LinkedPool could be duplicated.
/// This contract is supposed to be used in conjunction with Synapse:Bridge:
/// - The bridged token has index == 0, and could not be duplicated in the tree.
/// - Other tokens (correlated to bridge token) could be duplicated in the tree. Every node token in the tree
/// is represented by a trade path from root token to node token.
/// > This is the reason why token could be duplicated. `nUSD -> USDC` and `nUSD -> USDT -> USDC` both represent
/// > USDC token, but via different paths from nUSD, the bridge token.
/// In addition to the standard IDefaultPool interface, LinkedPool also implements getters to observe the internal
/// tree, as well as the best path finder between any two tokens in the tree.
/// Note: LinkedPool assumes that the added pool tokens have no transfer fees enabled.
contract LinkedPool is TokenTree, Ownable, ILinkedPool {
    using SafeERC20 for IERC20;
    using UniversalTokenLib for address;

    /// @notice Replicates signature of `TokenSwap` event from Default Pools.
    event TokenSwap(address indexed buyer, uint256 tokensSold, uint256 tokensBought, uint128 soldId, uint128 boughtId);

    // solhint-disable-next-line no-empty-blocks
    constructor(address bridgeToken) TokenTree(bridgeToken) {}

    // ═════════════════════════════════════════════════ EXTERNAL ══════════════════════════════════════════════════════

    /// @notice Adds a pool having `N` pool tokens to the tree by adding `N-1` new nodes
    /// as the children of the given node. Given node needs to represent a token from the pool.
    /// @dev `poolModule` should be set to address(this) if the pool conforms to IDefaultPool interface.
    /// Otherwise, it should be set to the address of the contract that implements the logic for pool handling.
    /// @param nodeIndex        The index of the node to which the pool will be added
    /// @param pool             The address of the pool
    /// @param poolModule       The address of the pool module
    function addPool(
        uint256 nodeIndex,
        address pool,
        address poolModule
    ) external onlyOwner {
        require(pool != address(0), "Pool address can't be zero");
        _addPool(nodeIndex, pool, poolModule);
    }

    /// @notice Updates the pool module logic address for the given pool.
    /// @dev Will revert if the pool is not present in the tree, or if the new pool module
    /// produces a different token list for the pool.
    function updatePoolModule(address pool, address newPoolModule) external onlyOwner {
        _updatePoolModule(pool, newPoolModule);
    }

    /// @inheritdoc ILinkedPool
    function swap(
        uint8 nodeIndexFrom,
        uint8 nodeIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        uint256 totalTokens = _nodes.length;
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "Deadline not met");
        require(
            nodeIndexFrom < totalTokens && nodeIndexTo < totalTokens && nodeIndexFrom != nodeIndexTo,
            "Swap not supported"
        );
        // Pull initial token from the user. LinkedPool assumes that the tokens have no transfer fees enabled,
        // thus the balance checks are omitted.
        address tokenIn = _nodes[nodeIndexFrom].token;
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), dx);
        amountOut = _multiSwap(nodeIndexFrom, nodeIndexTo, dx).amountOut;
        require(amountOut >= minDy, "Swap didn't result in min tokens");
        // Transfer the tokens to the user
        IERC20(_nodes[nodeIndexTo].token).safeTransfer(msg.sender, amountOut);
        // Emit the event
        emit TokenSwap(msg.sender, dx, amountOut, nodeIndexFrom, nodeIndexTo);
    }

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /// Note: this calculates a quote for a predefined swap path between two tokens. If any of the tokens is
    /// presented more than once in the internal tree, there might be a better quote. Integration should use
    /// findBestPath() instead. This function is present for backwards compatibility.
    /// @inheritdoc ILinkedPool
    function calculateSwap(
        uint8 nodeIndexFrom,
        uint8 nodeIndexTo,
        uint256 dx
    ) external view returns (uint256 amountOut) {
        uint256 totalTokens = _nodes.length;
        // Check that the token indexes are within range
        if (nodeIndexFrom >= totalTokens || nodeIndexTo >= totalTokens) {
            return 0;
        }
        // Check that the token indexes are not the same
        if (nodeIndexFrom == nodeIndexTo) {
            return 0;
        }
        // Calculate the quote by following the path from "tokenFrom" node to "tokenTo" node in the stored tree
        // This function might be called by Synapse:Bridge before the swap, so we don't waste gas checking if pool is paused,
        // as the swap will fail anyway if it is.
        amountOut = _getMultiSwapQuote({
            nodeIndexFrom: nodeIndexFrom,
            nodeIndexTo: nodeIndexTo,
            amountIn: dx,
            probePaused: false
        }).amountOut;
    }

    /// @inheritdoc ILinkedPool
    function areConnectedTokens(address tokenIn, address tokenOut) external view returns (bool areConnected) {
        // Tokens are considered connected, if they are both present in the tree
        return _tokenNodes[tokenIn].length > 0 && _tokenNodes[tokenOut].length > 0;
    }

    /// Note: this could be potentially a gas expensive operation. This is used by SwapQuoterV2 to get the best quote
    /// for tokenIn -> tokenOut swap request (the call to SwapQuoter is an off-chain call).
    /// This should NOT be used as a part of "find path + perform a swap" on-chain flow.
    /// Instead, do an off-chain call to findBestPath() and then perform a swap using the found node indexes.
    /// As pair of token nodes defines only a single trade path (tree has no cycles), it will be possible to go
    /// through the found path by simply supplying the found indexes (instead of searching for the best path again).
    /// @inheritdoc ILinkedPool
    function findBestPath(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    )
        external
        view
        returns (
            uint8 nodeIndexFromBest,
            uint8 nodeIndexToBest,
            uint256 amountOutBest
        )
    {
        // Check that the tokens are not the same and that the amount is not zero
        if (tokenIn == tokenOut || amountIn == 0) {
            return (0, 0, 0);
        }
        uint256 nodesFrom = _tokenNodes[tokenIn].length;
        uint256 nodesTo = _tokenNodes[tokenOut].length;
        // Go through every node that represents `tokenIn`
        for (uint256 i = 0; i < nodesFrom; ++i) {
            uint256 nodeIndexFrom = _tokenNodes[tokenIn][i];
            // Go through every node that represents `tokenOut`
            for (uint256 j = 0; j < nodesTo; ++j) {
                uint256 nodeIndexTo = _tokenNodes[tokenOut][j];
                // Calculate the quote by following the path from "tokenFrom" node to "tokenTo" node in the stored tree
                // We discard any paths with paused pools, as it's not possible to swap via them anyway.
                uint256 amountOut = _getMultiSwapQuote({
                    nodeIndexFrom: nodeIndexFrom,
                    nodeIndexTo: nodeIndexTo,
                    amountIn: amountIn,
                    probePaused: true
                }).amountOut;
                if (amountOut > amountOutBest) {
                    amountOutBest = amountOut;
                    nodeIndexFromBest = uint8(nodeIndexFrom);
                    nodeIndexToBest = uint8(nodeIndexTo);
                }
            }
        }
    }

    /// @inheritdoc ILinkedPool
    function getToken(uint8 index) external view returns (address token) {
        require(index < _nodes.length, "Out of range");
        return _nodes[index].token;
    }

    /// @inheritdoc ILinkedPool
    function tokenNodesAmount() external view returns (uint256) {
        return _nodes.length;
    }

    /// @inheritdoc ILinkedPool
    function getAttachedPools(uint8 index) external view returns (address[] memory pools) {
        require(index < _nodes.length, "Out of range");
        pools = new address[](_pools.length);
        uint256 amountAttached = 0;
        uint256 poolsMask = _attachedPools[index];
        for (uint256 i = 0; i < pools.length; ) {
            // Check if _pools[i] is attached to the node at `index`
            unchecked {
                if ((poolsMask >> i) & 1 == 1) {
                    pools[amountAttached++] = _pools[i];
                }
                ++i;
            }
        }
        // Use assembly to shrink the array to the actual size
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(pools, amountAttached)
        }
    }

    /// @inheritdoc ILinkedPool
    function getTokenIndexes(address token) external view returns (uint256[] memory nodes) {
        nodes = _tokenNodes[token];
    }

    /// @inheritdoc ILinkedPool
    function getPoolModule(address pool) external view returns (address) {
        return _poolMap[pool].module;
    }

    /// @inheritdoc ILinkedPool
    function getNodeParent(uint256 nodeIndex) external view returns (uint256 parentIndex, address parentPool) {
        require(nodeIndex < _nodes.length, "Out of range");
        uint8 depth = _nodes[nodeIndex].depth;
        // Check if node is root, in which case there is no parent
        if (depth > 0) {
            parentIndex = _extractNodeIndex(_rootPath[nodeIndex], depth - 1);
            parentPool = _pools[_nodes[nodeIndex].poolIndex];
        }
    }

    // ══════════════════════════════════════════════ INTERNAL LOGIC ═══════════════════════════════════════════════════

    /// @dev Performs a single swap between two nodes using the given pool.
    /// Assumes that the initial token is already in this contract.
    function _poolSwap(
        address poolModule,
        address pool,
        uint256 nodeIndexFrom,
        uint256 nodeIndexTo,
        uint256 amountIn
    ) internal override returns (uint256 amountOut) {
        address tokenFrom = _nodes[nodeIndexFrom].token;
        address tokenTo = _nodes[nodeIndexTo].token;
        // Approve pool to spend the token, if needed
        if (poolModule == address(this)) {
            tokenFrom.universalApproveInfinity(pool, amountIn);
            // Pool conforms to IDefaultPool interface. Note: we check minDy and deadline outside of this function.
            amountOut = IDefaultPool(pool).swap({
                tokenIndexFrom: tokenIndexes[pool][tokenFrom],
                tokenIndexTo: tokenIndexes[pool][tokenTo],
                dx: amountIn,
                minDy: 0,
                deadline: type(uint256).max
            });
        } else {
            // Here we pass both token address and its index to the pool module, so it doesn't need to store
            // index<>token mapping. This allows Pool Module to be implemented in a stateless way, as some
            // pools require token index for interactions, while others require token address.
            // poolSwap(pool, tokenFrom, tokenTo, amountIn)
            bytes memory payload = abi.encodeWithSelector(
                IPoolModule.poolSwap.selector,
                pool,
                IndexedToken({index: tokenIndexes[pool][tokenFrom], token: tokenFrom}),
                IndexedToken({index: tokenIndexes[pool][tokenTo], token: tokenTo}),
                amountIn
            );
            // Delegate swap logic to Pool Module. It should approve the pool to spend the token, if needed.
            // Note that poolModule address is set by the contract owner, so it's safe to delegatecall it.
            (bool success, bytes memory result) = poolModule.delegatecall(payload);
            require(success, "Swap failed");
            // Pool Modules are whitelisted, so we can trust the returned amountOut value.
            amountOut = abi.decode(result, (uint256));
        }
    }

    // ══════════════════════════════════════════════ INTERNAL VIEWS ═══════════════════════════════════════════════════

    /// @dev Returns the amount of tokens that will be received from a single swap.
    function _getPoolQuote(
        address poolModule,
        address pool,
        uint256 nodeIndexFrom,
        uint256 nodeIndexTo,
        uint256 amountIn,
        bool probePaused
    ) internal view override returns (uint256 amountOut) {
        if (poolModule == address(this)) {
            // Check if pool is paused, if requested
            if (probePaused) {
                // We issue a static call in case the pool does not conform to IPausable interface.
                (bool success, bytes memory returnData) = pool.staticcall(
                    abi.encodeWithSelector(IPausable.paused.selector)
                );
                if (success && abi.decode(returnData, (bool))) {
                    // Pool is paused, return zero
                    return 0;
                }
            }
            // Pool conforms to IDefaultPool interface.
            try
                IDefaultPool(pool).calculateSwap({
                    tokenIndexFrom: tokenIndexes[pool][_nodes[nodeIndexFrom].token],
                    tokenIndexTo: tokenIndexes[pool][_nodes[nodeIndexTo].token],
                    dx: amountIn
                })
            returns (uint256 amountOut_) {
                amountOut = amountOut_;
            } catch {
                // Return zero if the pool getter reverts for any reason
                amountOut = 0;
            }
        } else {
            // Ask Pool Module to calculate the quote
            address tokenFrom = _nodes[nodeIndexFrom].token;
            address tokenTo = _nodes[nodeIndexTo].token;
            // Here we pass both token address and its index to the pool module, so it doesn't need to store
            // index<>token mapping. This allows Pool Module to be implemented in a stateless way, as some
            // pools require token index for interactions, while others require token address.
            try
                IPoolModule(poolModule).getPoolQuote(
                    pool,
                    IndexedToken({index: tokenIndexes[pool][tokenFrom], token: tokenFrom}),
                    IndexedToken({index: tokenIndexes[pool][tokenTo], token: tokenTo}),
                    amountIn,
                    probePaused
                )
            returns (uint256 amountOut_) {
                amountOut = amountOut_;
            } catch {
                // Return zero if the pool module getter reverts for any reason
                amountOut = 0;
            }
        }
    }

    /// @dev Returns the tokens in the pool at the given address.
    function _getPoolTokens(address poolModule, address pool) internal view override returns (address[] memory tokens) {
        if (poolModule == address(this)) {
            // Pool conforms to IDefaultPool interface.
            // First, figure out how many tokens there are in the pool
            uint256 numTokens = 0;
            while (true) {
                try IDefaultPool(pool).getToken(uint8(numTokens)) returns (address) {
                    unchecked {
                        ++numTokens;
                    }
                } catch {
                    break;
                }
            }
            // Then allocate the memory, and get the tokens
            tokens = new address[](numTokens);
            for (uint256 i = 0; i < numTokens; ) {
                tokens[i] = IDefaultPool(pool).getToken(uint8(i));
                unchecked {
                    ++i;
                }
            }
        } else {
            // Ask Pool Module to return the tokens
            // Note: this will revert if pool is not supported by the module, enforcing the invariant
            // that the added pools are supported by their specified module.
            tokens = IPoolModule(poolModule).getPoolTokens(pool);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPausable {
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IndexedToken} from "../libs/Structs.sol";

interface IPoolModule {
    /// @notice Performs a swap via the given pool, assuming `tokenFrom` is already in the contract.
    /// After the call, the contract should have custody over the received `tokenTo` tokens.
    /// @dev This will be used via delegatecall from LinkedPool, which will have the custody over the initial tokens,
    /// and will only use the correct pool address for interacting with the Pool Module.
    /// Note: Pool Module is responsible for issuing the token approvals, if `pool` requires them.
    /// Note: execution needs to be reverted, if swap fails for any reason.
    /// @param pool         Address of the pool
    /// @param tokenFrom    Token to swap from
    /// @param tokenTo      Token to swap to
    /// @param amountIn     Amount of tokenFrom to swap
    /// @return amountOut   Amount of tokenTo received after the swap
    function poolSwap(
        address pool,
        IndexedToken memory tokenFrom,
        IndexedToken memory tokenTo,
        uint256 amountIn
    ) external returns (uint256 amountOut);

    /// @notice Returns a quote for a swap via the given pool.
    /// @dev This will be used by LinkedPool, which is supposed to pass only the correct pool address.
    /// Note: Pool Module should bubble the revert, if pool quote fails for any reason.
    /// Note: Pool Module should only revert if the pool is paused, if `probePaused` is true.
    /// @param pool         Address of the pool
    /// @param tokenFrom    Token to swap from
    /// @param tokenTo      Token to swap to
    /// @param amountIn     Amount of tokenFrom to swap
    /// @param probePaused  Whether to check if the pool is paused
    /// @return amountOut   Amount of tokenTo received after the swap
    function getPoolQuote(
        address pool,
        IndexedToken memory tokenFrom,
        IndexedToken memory tokenTo,
        uint256 amountIn,
        bool probePaused
    ) external view returns (uint256 amountOut);

    /// @notice Returns the list of tokens in the pool. Tokens should be returned in the same order
    /// that is used by the pool for indexing.
    /// @dev Execution needs to be reverted, if pool tokens retrieval fails for any reason, e.g.
    /// if the given pool is not compatible with the Pool Module.
    /// @param pool         Address of the pool
    /// @return tokens      Array of tokens in the pool
    function getPoolTokens(address pool) external view returns (address[] memory tokens);
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
pragma solidity 0.8.17;

/// TokenTree implements the internal logic for storing a set of tokens in a rooted tree.
/// - Root node represents a Synapse-bridged token.
/// - The root token could not appear more than once in the tree.
/// - Other tree nodes represent tokens that are correlated with the root token.
/// - These other tokens could appear more than once in the tree.
/// - Every edge between a child and a parent node is associated with a single liquidity pool that contains both tokens.
/// - The tree is rooted => the root of the tree has a zero depth. A child node depth is one greater than its parent.
/// - Every node can have arbitrary amount of children.
/// - New nodes are added to the tree by "attaching" a pool to an existing node. This adds all the other pool tokens
/// as new children of the existing node (which represents one of the tokens from the pool).
/// - Pool could be only attached once to any given node. Pool could not be attached to a node, if it connects the node
/// with its parent.
/// - Pool could be potentially attached to two different nodes in the tree.
/// - By definition a tree has no cycles, so there exists only one path between any two nodes. Every edge on this path
/// represents a liquidity pool, and the whole path represents a series of swaps that lead from one token to another.
/// - Paths that contain a pool more than once are not allowed, and are not used for quotes/swaps. This is due to
/// the fact that it's impossible to get an accurate quote for the second swap through the pool in the same tx.
/// > This contract is only responsible for storing and traversing the tree. The swap/quote logic, as well as
/// > transformation of the inner tree into IDefaultPool interface is implemented in the child contract.
abstract contract TokenTree {
    /// @notice Struct so store the tree nodes
    /// @param token        Address of the token represented by this node
    /// @param depth        Depth of the node in the tree
    /// @param poolIndex    Index of the pool that connects this node to its parent (0 if root)
    struct Node {
        address token;
        uint8 depth;
        uint8 poolIndex;
    }

    /// @notice Struct to store the liquidity pools
    /// @dev Module address is used for delegate calls to get swap quotes, token indexes, etc.
    /// Set to address(this) if pool conforms to IDefaultPool interface. Set to 0x0 if pool is not supported.
    /// @param module       Address of the module contract for this pool
    /// @param index        Index of the pool in the `_pools` array
    struct Pool {
        address module;
        uint8 index;
    }

    /// @notice Struct to get around stack too deep error
    /// @param from         Node representing the token we are swapping from
    /// @param to           Node representing the token we are swapping to
    struct Request {
        Node from;
        Node to;
        bool probePaused;
    }

    /// @notice Struct to get around stack too deep error
    /// @param visitedPoolsMask     Bitmask of pools visited so far
    /// @param amountOut            Amount of tokens received so far
    struct Route {
        uint256 visitedPoolsMask;
        uint256 amountOut;
    }

    // ══════════════════════════════════════════════════ STORAGE ══════════════════════════════════════════════════════

    // The nodes of the tree are stored in an array. The root node is at index 0.
    Node[] internal _nodes;

    // The list of all supported liquidity pools. All values are unique.
    address[] internal _pools;

    // (pool address => pool description)
    mapping(address => Pool) internal _poolMap;

    // (pool => token => tokenIndex) for each pool, stores the index of each token in the pool.
    mapping(address => mapping(address => uint8)) public tokenIndexes;

    // (token => nodes) for each token, stores the indexes of all nodes that represent this token.
    mapping(address => uint256[]) internal _tokenNodes;

    // The full path from every node to the root is stored using bitmasks in the following way:
    // - For a node with index i at depth N, lowest N + 1 bytes of _rootPath[i] are used to store the path to the root.
    // - The lowest byte is always the root index. This is always 0, but we store this for consistency.
    // - The highest byte is always the node index. This is always i, but we store this for consistency.
    // - The remaining bytes are indexes of the nodes on the path from the node to the root (from highest to lowest).
    // This way the finding the lowest common ancestor of two nodes is reduced to finding the lowest differing byte
    // in node's encoded root paths.
    uint256[] internal _rootPath;

    // (node => bitmask with all attached pools to the node).
    // Note: This excludes the pool that connects the node to its parent.
    mapping(uint256 => uint256) internal _attachedPools;

    // ════════════════════════════════════════════════ CONSTRUCTOR ════════════════════════════════════════════════════

    constructor(address bridgeToken) {
        // The root node is always the bridge token
        _addNode({token: bridgeToken, depth: 0, poolIndex: 0, rootPathParent: 0});
        // Push the empty pool so that `poolIndex` for non-root nodes is never 0
        _pools.push(address(0));
    }

    // ══════════════════════════════════════════════ INTERNAL LOGIC ═══════════════════════════════════════════════════

    /// @dev Adds a pool having `N` pool tokens to the tree by adding `N-1` new nodes
    /// as the children of the given node. Given node needs to represent a token from the pool.
    function _addPool(
        uint256 nodeIndex,
        address pool,
        address poolModule
    ) internal {
        require(nodeIndex < _nodes.length, "Out of range");
        Node memory node = _nodes[nodeIndex];
        if (poolModule == address(0)) poolModule = address(this);
        (bool wasAdded, uint8 poolIndex) = (false, _poolMap[pool].index);
        if (poolIndex == 0) {
            require(_pools.length <= type(uint8).max, "Too many pools");
            // Can do the unsafe cast here, as we just checked that pool index fits into uint8
            poolIndex = uint8(_pools.length);
            _pools.push(pool);
            _poolMap[pool] = Pool({module: poolModule, index: poolIndex});
            wasAdded = true;
        } else {
            // Check if the existing pool could be added to the node. This enforces some sanity checks,
            // as well the invariant that any path from root to node doesn't contain the same pool twice.
            _checkPoolAddition(nodeIndex, node.depth, poolIndex);
        }
        // Remember that the pool is attached to the node
        _attachedPools[nodeIndex] |= 1 << poolIndex;
        address[] memory tokens = _getPoolTokens(poolModule, pool);
        uint256 numTokens = tokens.length;
        bool nodeFound = false;
        unchecked {
            uint8 childDepth = node.depth + 1;
            uint256 rootPathParent = _rootPath[nodeIndex];
            for (uint256 i = 0; i < numTokens; ++i) {
                address token = tokens[i];
                // Save token indexes if this is a new pool
                if (wasAdded) {
                    tokenIndexes[pool][token] = uint8(i);
                }
                // Add new nodes to the tree
                if (token == node.token) {
                    nodeFound = true;
                    continue;
                }
                _addNode(token, childDepth, poolIndex, rootPathParent);
            }
        }
        require(nodeFound, "Node token not found in the pool");
    }

    /// @dev Adds a new node to the tree and saves its path to the root.
    function _addNode(
        address token,
        uint8 depth,
        uint8 poolIndex,
        uint256 rootPathParent
    ) internal {
        // Index of the newly inserted child node
        uint256 nodeIndex = _nodes.length;
        require(nodeIndex <= type(uint8).max, "Too many nodes");
        // Don't add the bridge token (root) twice. This may happen if we add a new pool containing the bridge token
        // to a few existing nodes. E.g. we have old nUSD/USDC/USDT pool, and we add a new nUSD/USDC pool. In this case
        // we attach nUSD/USDC pool to root, and then attach old nUSD/USDC/USDT pool to the newly added USDC node
        // to enable nUSD -> USDC -> USDT swaps via new + old pools.
        if (_nodes.length > 0 && token == _nodes[0].token) {
            return;
        }
        _nodes.push(Node({token: token, depth: depth, poolIndex: poolIndex}));
        _tokenNodes[token].push(nodeIndex);
        // Push the root path for the new node. The root path is the inserted node index + the parent's root path.
        _rootPath.push((nodeIndex << (8 * depth)) | rootPathParent);
    }

    /// @dev Updates the Pool Module for the given pool.
    /// Will revert, if the pool was not previously added, or if the new pool module produces a different list of tokens.
    function _updatePoolModule(address pool, address newPoolModule) internal {
        // Check that pool was previously added
        address oldPoolModule = _poolMap[pool].module;
        require(oldPoolModule != address(0), "Pool not found");
        // Sanity check that pool modules produce the same list of tokens
        address[] memory oldTokens = _getPoolTokens(oldPoolModule, pool);
        address[] memory newTokens = _getPoolTokens(newPoolModule, pool);
        require(oldTokens.length == newTokens.length, "Different token lists");
        for (uint256 i = 0; i < oldTokens.length; ++i) {
            require(oldTokens[i] == newTokens[i], "Different token lists");
        }
        // Update the pool module
        _poolMap[pool].module = newPoolModule;
    }

    // ══════════════════════════════════════ INTERNAL LOGIC: MULTIPLE POOLS ═══════════════════════════════════════════

    /// @dev Performs a multi-hop swap by following the path from "tokenFrom" node to "tokenTo" node
    /// in the stored tree. Token indexes are checked to be within range and not the same.
    /// Assumes that the initial token is already in this contract.
    function _multiSwap(
        uint256 nodeIndexFrom,
        uint256 nodeIndexTo,
        uint256 amountIn
    ) internal returns (Route memory route) {
        // Struct to get around stack too deep
        Request memory req = Request({from: _nodes[nodeIndexFrom], to: _nodes[nodeIndexTo], probePaused: false});
        uint256 rootPathFrom = _rootPath[nodeIndexFrom];
        uint256 rootPathTo = _rootPath[nodeIndexTo];
        // Find the depth where the paths diverge
        uint256 depthDiff = _depthDiff(rootPathFrom, rootPathTo);
        // Check if `nodeIndexTo` is an ancestor of `nodeIndexFrom`. True if paths diverge below `nodeIndexTo`.
        if (depthDiff > req.to.depth) {
            // Path from "tokenFrom" to root includes "tokenTo",
            // so we simply go from "tokenFrom" to "tokenTo" in the "to root" direction.
            return _multiSwapToRoot(0, rootPathFrom, req.from.depth, req.to.depth, amountIn);
        }
        // Check if `nodeIndexFrom` is an ancestor of `nodeIndexTo`. True if paths diverge below `nodeIndexFrom`.
        if (depthDiff > req.from.depth) {
            // Path from "tokenTo" to root includes "tokenFrom",
            // so we simply go from "tokenTo" to "tokenFrom" in the "from root" direction.
            return _multiSwapFromRoot(0, rootPathTo, req.from.depth, req.to.depth, amountIn);
        }
        // First, we traverse up the tree from "tokenFrom" to one level deeper the lowest common ancestor.
        route = _multiSwapToRoot(0, rootPathFrom, req.from.depth, depthDiff, amountIn);
        // Check if we need to do a sibling swap. When the two nodes are connected to the same parent via the same pool,
        // we do a direct swap between the two nodes, instead of doing two swaps through the parent using the same pool.
        uint256 lastNodeIndex = _extractNodeIndex(rootPathFrom, depthDiff);
        uint256 siblingIndex = _extractNodeIndex(rootPathTo, depthDiff);
        uint256 firstPoolIndex = _nodes[lastNodeIndex].poolIndex;
        uint256 secondPoolIndex = _nodes[siblingIndex].poolIndex;
        if (firstPoolIndex == secondPoolIndex) {
            // Swap lastNode -> sibling
            (route.visitedPoolsMask, route.amountOut) = _singleSwap(
                route.visitedPoolsMask,
                firstPoolIndex,
                lastNodeIndex,
                siblingIndex,
                route.amountOut
            );
        } else {
            // Swap lastNode -> parent
            uint256 parentIndex = _extractNodeIndex(rootPathFrom, depthDiff - 1);
            (route.visitedPoolsMask, route.amountOut) = _singleSwap(
                route.visitedPoolsMask,
                firstPoolIndex,
                lastNodeIndex,
                parentIndex,
                route.amountOut
            );
            // Swap parent -> sibling
            (route.visitedPoolsMask, route.amountOut) = _singleSwap(
                route.visitedPoolsMask,
                secondPoolIndex,
                parentIndex,
                siblingIndex,
                route.amountOut
            );
        }
        // Finally, we traverse down the tree from the lowest common ancestor to "tokenTo".
        return _multiSwapFromRoot(route.visitedPoolsMask, rootPathTo, depthDiff, req.to.depth, route.amountOut);
    }

    /// @dev Performs a multi-hop swap, going in "from root direction" (where depth increases)
    /// via the given `rootPath` from `depthFrom` to `depthTo`.
    /// Assumes that the initial token is already in this contract.
    function _multiSwapFromRoot(
        uint256 visitedPoolsMask,
        uint256 rootPath,
        uint256 depthFrom,
        uint256 depthTo,
        uint256 amountIn
    ) internal returns (Route memory route) {
        uint256 nodeIndex = _extractNodeIndex(rootPath, depthFrom);
        // Traverse down the tree following `rootPath` from `depthFrom` to `depthTo`.
        for (uint256 depth = depthFrom; depth < depthTo; ) {
            // Get the child node
            unchecked {
                ++depth;
            }
            uint256 childIndex = _extractNodeIndex(rootPath, depth);
            // Swap node -> child
            (visitedPoolsMask, amountIn) = _singleSwap(
                visitedPoolsMask,
                _nodes[childIndex].poolIndex,
                nodeIndex,
                childIndex,
                amountIn
            );
            nodeIndex = childIndex;
        }
        route.visitedPoolsMask = visitedPoolsMask;
        route.amountOut = amountIn;
    }

    /// @dev Performs a multi-hop swap, going in "to root direction" (where depth decreases)
    /// via the given `rootPath` from `depthFrom` to `depthTo`.
    /// Assumes that the initial token is already in this contract.
    function _multiSwapToRoot(
        uint256 visitedPoolsMask,
        uint256 rootPath,
        uint256 depthFrom,
        uint256 depthTo,
        uint256 amountIn
    ) internal returns (Route memory route) {
        uint256 nodeIndex = _extractNodeIndex(rootPath, depthFrom);
        // Traverse up the tree following `rootPath` from `depthFrom` to `depthTo`.
        for (uint256 depth = depthFrom; depth > depthTo; ) {
            // Get the parent node
            unchecked {
                --depth; // depth > 0 so we can do unchecked math
            }
            uint256 parentIndex = _extractNodeIndex(rootPath, depth);
            // Swap node -> parent
            (visitedPoolsMask, amountIn) = _singleSwap(
                visitedPoolsMask,
                _nodes[nodeIndex].poolIndex,
                nodeIndex,
                parentIndex,
                amountIn
            );
            nodeIndex = parentIndex;
        }
        route.visitedPoolsMask = visitedPoolsMask;
        route.amountOut = amountIn;
    }

    // ════════════════════════════════════════ INTERNAL LOGIC: SINGLE POOL ════════════════════════════════════════════

    /// @dev Performs a single swap between two nodes using the given pool.
    /// Assumes that the initial token is already in this contract.
    function _poolSwap(
        address poolModule,
        address pool,
        uint256 nodeIndexFrom,
        uint256 nodeIndexTo,
        uint256 amountIn
    ) internal virtual returns (uint256 amountOut);

    /// @dev Performs a single swap between two nodes using the given pool given the set of pools
    /// we have already used on the path. Returns the updated set of pools and the amount of tokens received.
    /// Assumes that the initial token is already in this contract.
    function _singleSwap(
        uint256 visitedPoolsMask,
        uint256 poolIndex,
        uint256 nodeIndexFrom,
        uint256 nodeIndexTo,
        uint256 amountIn
    ) internal returns (uint256 visitedPoolsMask_, uint256 amountOut) {
        if (visitedPoolsMask & (1 << poolIndex) != 0) {
            // If we already used this pool on the path, we can't use it again.
            revert("Can't use same pool twice");
        }
        // Mark the pool as visited
        visitedPoolsMask_ = visitedPoolsMask | (1 << poolIndex);
        address pool = _pools[poolIndex];
        amountOut = _poolSwap(_poolMap[pool].module, pool, nodeIndexFrom, nodeIndexTo, amountIn);
    }

    // ══════════════════════════════════════ INTERNAL VIEWS: MULTIPLE POOLS ═══════════════════════════════════════════

    /// @dev Calculates the multi-hop swap quote by following the path from "tokenFrom" node to "tokenTo" node
    /// in the stored tree. Token indexes are checked to be within range and not the same.
    function _getMultiSwapQuote(
        uint256 nodeIndexFrom,
        uint256 nodeIndexTo,
        uint256 amountIn,
        bool probePaused
    ) internal view returns (Route memory route) {
        // Struct to get around stack too deep
        Request memory req = Request({from: _nodes[nodeIndexFrom], to: _nodes[nodeIndexTo], probePaused: probePaused});
        uint256 rootPathFrom = _rootPath[nodeIndexFrom];
        uint256 rootPathTo = _rootPath[nodeIndexTo];
        // Find the depth where the paths diverge
        uint256 depthDiff = _depthDiff(rootPathFrom, rootPathTo);
        // Check if `nodeIndexTo` is an ancestor of `nodeIndexFrom`. True if paths diverge below `nodeIndexTo`.
        if (depthDiff > req.to.depth) {
            // Path from "tokenFrom" to root includes "tokenTo",
            // so we simply go from "tokenFrom" to "tokenTo" in the "to root" direction.
            return _getMultiSwapToRootQuote(0, rootPathFrom, req.from.depth, req.to.depth, amountIn, probePaused);
        }
        // Check if `nodeIndexFrom` is an ancestor of `nodeIndexTo`. True if paths diverge below `nodeIndexFrom`.
        if (depthDiff > req.from.depth) {
            // Path from "tokenTo" to root includes "tokenFrom",
            // so we simply go from "tokenTo" to "tokenFrom" in the "from root" direction.
            return _getMultiSwapFromRootQuote(0, rootPathTo, req.from.depth, req.to.depth, amountIn, probePaused);
        }
        // First, we traverse up the tree from "tokenFrom" to one level deeper the lowest common ancestor.
        route = _getMultiSwapToRootQuote(
            route.visitedPoolsMask,
            rootPathFrom,
            req.from.depth,
            depthDiff,
            amountIn,
            req.probePaused
        );
        // Check if we need to do a sibling swap. When the two nodes are connected to the same parent via the same pool,
        // we do a direct swap between the two nodes, instead of doing two swaps through the parent using the same pool.
        uint256 lastNodeIndex = _extractNodeIndex(rootPathFrom, depthDiff);
        uint256 siblingIndex = _extractNodeIndex(rootPathTo, depthDiff);
        uint256 firstPoolIndex = _nodes[lastNodeIndex].poolIndex;
        uint256 secondPoolIndex = _nodes[siblingIndex].poolIndex;
        if (firstPoolIndex == secondPoolIndex) {
            // Swap lastNode -> sibling
            (route.visitedPoolsMask, route.amountOut) = _getSingleSwapQuote(
                route.visitedPoolsMask,
                firstPoolIndex,
                lastNodeIndex,
                siblingIndex,
                route.amountOut,
                req.probePaused
            );
        } else {
            // Swap lastNode -> parent
            uint256 parentIndex = _extractNodeIndex(rootPathFrom, depthDiff - 1);
            (route.visitedPoolsMask, route.amountOut) = _getSingleSwapQuote(
                route.visitedPoolsMask,
                firstPoolIndex,
                lastNodeIndex,
                parentIndex,
                route.amountOut,
                req.probePaused
            );
            // Swap parent -> sibling
            (route.visitedPoolsMask, route.amountOut) = _getSingleSwapQuote(
                route.visitedPoolsMask,
                secondPoolIndex,
                parentIndex,
                siblingIndex,
                route.amountOut,
                req.probePaused
            );
        }
        // Finally, we traverse down the tree from the lowest common ancestor to "tokenTo".
        return
            _getMultiSwapFromRootQuote(
                route.visitedPoolsMask,
                rootPathTo,
                depthDiff,
                req.to.depth,
                route.amountOut,
                req.probePaused
            );
    }

    /// @dev Calculates the amount of tokens that will be received from a multi-hop swap,
    /// going in "from root direction" (where depth increases) via the given `rootPath` from `depthFrom` to `depthTo`.
    function _getMultiSwapFromRootQuote(
        uint256 visitedPoolsMask,
        uint256 rootPath,
        uint256 depthFrom,
        uint256 depthTo,
        uint256 amountIn,
        bool probePaused
    ) internal view returns (Route memory route) {
        uint256 nodeIndex = _extractNodeIndex(rootPath, depthFrom);
        // Traverse down the tree following `rootPath` from `depthFrom` to `depthTo`.
        for (uint256 depth = depthFrom; depth < depthTo; ) {
            // Get the child node
            unchecked {
                ++depth;
            }
            uint256 childIndex = _extractNodeIndex(rootPath, depth);
            // Swap node -> child
            (visitedPoolsMask, amountIn) = _getSingleSwapQuote(
                visitedPoolsMask,
                _nodes[childIndex].poolIndex,
                nodeIndex,
                childIndex,
                amountIn,
                probePaused
            );
            nodeIndex = childIndex;
        }
        route.visitedPoolsMask = visitedPoolsMask;
        route.amountOut = amountIn;
    }

    /// @dev Calculates the amount of tokens that will be received from a multi-hop swap,
    /// going in "to root direction" (where depth decreases) via the given `rootPath` from `depthFrom` to `depthTo`.
    function _getMultiSwapToRootQuote(
        uint256 visitedPoolsMask,
        uint256 rootPath,
        uint256 depthFrom,
        uint256 depthTo,
        uint256 amountIn,
        bool probePaused
    ) internal view returns (Route memory route) {
        uint256 nodeIndex = _extractNodeIndex(rootPath, depthFrom);
        // Traverse up the tree following `rootPath` from `depthFrom` to `depthTo`.
        for (uint256 depth = depthFrom; depth > depthTo; ) {
            // Get the parent node
            unchecked {
                --depth; // depth > 0 so we can do unchecked math
            }
            uint256 parentIndex = _extractNodeIndex(rootPath, depth);
            // Swap node -> parent
            (visitedPoolsMask, amountIn) = _getSingleSwapQuote(
                visitedPoolsMask,
                _nodes[nodeIndex].poolIndex,
                nodeIndex,
                parentIndex,
                amountIn,
                probePaused
            );
            nodeIndex = parentIndex;
        }
        route.visitedPoolsMask = visitedPoolsMask;
        route.amountOut = amountIn;
    }

    // ════════════════════════════════════════ INTERNAL VIEWS: SINGLE POOL ════════════════════════════════════════════

    /// @dev Returns the tokens in the pool at the given address.
    function _getPoolTokens(address poolModule, address pool) internal view virtual returns (address[] memory tokens);

    /// @dev Returns the amount of tokens that will be received from a single swap.
    /// Will check if the pool is paused beforehand, if requested.
    function _getPoolQuote(
        address poolModule,
        address pool,
        uint256 nodeIndexFrom,
        uint256 nodeIndexTo,
        uint256 amountIn,
        bool probePaused
    ) internal view virtual returns (uint256 amountOut);

    /// @dev Calculates the amount of tokens that will be received from a single swap given the set of pools
    /// we have already used on the path. Returns the updated set of pools and the amount of tokens received.
    function _getSingleSwapQuote(
        uint256 visitedPoolsMask,
        uint256 poolIndex,
        uint256 nodeIndexFrom,
        uint256 nodeIndexTo,
        uint256 amountIn,
        bool probePaused
    ) internal view returns (uint256 visitedPoolsMask_, uint256 amountOut) {
        if (visitedPoolsMask & (1 << poolIndex) != 0) {
            // If we already used this pool on the path, we can't use it again.
            // Return the full mask and zero amount to indicate that the swap is not possible.
            return (type(uint256).max, 0);
        }
        // Otherwise, mark the pool as visited
        visitedPoolsMask_ = visitedPoolsMask | (1 << poolIndex);
        address pool = _pools[poolIndex];
        // Pass the parameter for whether we want to check that the pool is paused or not.
        amountOut = _getPoolQuote(_poolMap[pool].module, pool, nodeIndexFrom, nodeIndexTo, amountIn, probePaused);
    }

    // ══════════════════════════════════════════════════ HELPERS ══════════════════════════════════════════════════════

    /// @dev Checks if a pool could be added to the tree at the given node. Requirements:
    /// - Pool is not already attached to the node: no need to add twice.
    /// - Pool is not present on the path from the node to root: this would invalidate swaps from added nodes to root,
    /// as this path would contain this pool twice.
    function _checkPoolAddition(
        uint256 nodeIndex,
        uint256 nodeDepth,
        uint8 poolIndex
    ) internal view {
        // Check that the pool is not already attached to the node
        require(_attachedPools[nodeIndex] & (1 << poolIndex) == 0, "Pool already attached");
        // Here we iterate over all nodes from the root to the node, and check that the pool connecting the current node
        // to its parent is not the pool we want to add. We skip the root node (depth 0), as it has no parent.
        uint256 rootPath = _rootPath[nodeIndex];
        for (uint256 d = 1; d <= nodeDepth; ) {
            uint256 nodeIndex_ = _extractNodeIndex(rootPath, d);
            require(_nodes[nodeIndex_].poolIndex != poolIndex, "Pool already on path to root");
            unchecked {
                ++d;
            }
        }
    }

    /// @dev Finds the lowest common ancestor of two different nodes in the tree.
    /// Node is defined by the path from the root to the node, and the depth of the node.
    function _depthDiff(uint256 rootPath0, uint256 rootPath1) internal pure returns (uint256 depthDiff) {
        // Xor the paths to get the first differing byte.
        // Nodes are different => root paths are different => the result is never zero.
        rootPath0 ^= rootPath1;
        // Sanity check for invariant: rootPath0 != rootPath1
        assert(rootPath0 != 0);
        // Traverse from root to node0 and node1 until the paths diverge.
        while ((rootPath0 & 0xFF) == 0) {
            // Shift off the lowest byte which are identical in both paths.
            rootPath0 >>= 8;
            unchecked {
                depthDiff++;
            }
        }
    }

    /// @dev Returns the index of the node at the given depth on the path from the root to the node.
    function _extractNodeIndex(uint256 rootPath, uint256 depth) internal pure returns (uint256 nodeIndex) {
        // Nodes on the path are stored from root to node (lowest to highest bytes).
        return (rootPath >> (8 * depth)) & 0xFF;
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