// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RAY} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";
import {BitMask} from "@gearbox-protocol/core-v3/contracts/libraries/BitMask.sol";

import {AbstractAdapter} from "../AbstractAdapter.sol";
import {AdapterType} from "@gearbox-protocol/sdk-gov/contracts/AdapterType.sol";

import {IAsset} from "../../integrations/balancer/IAsset.sol";
import {
    IBalancerV2Vault,
    SwapKind,
    SingleSwap,
    FundManagement,
    BatchSwapStep,
    JoinPoolRequest,
    ExitPoolRequest
} from "../../integrations/balancer/IBalancerV2Vault.sol";
import {
    IBalancerV2VaultAdapter, SingleSwapDiff, PoolStatus
} from "../../interfaces/balancer/IBalancerV2VaultAdapter.sol";

/// @title Balancer V2 Vault adapter
/// @notice Implements logic allowing CAs to swap through and LP in Balancer vaults
contract BalancerV2VaultAdapter is AbstractAdapter, IBalancerV2VaultAdapter {
    using BitMask for uint256;

    AdapterType public constant override _gearboxAdapterType = AdapterType.BALANCER_VAULT;
    uint16 public constant override _gearboxAdapterVersion = 3_00;

    /// @notice Mapping from poolId to status of the pool: whether it is not supported, fully supported or swap-only
    mapping(bytes32 => PoolStatus) public override poolStatus;

    /// @notice Constructor
    /// @param _creditManager Credit manager address
    /// @param _vault Balancer vault address
    constructor(address _creditManager, address _vault)
        AbstractAdapter(_creditManager, _vault) // U:[BAL2-1]
    {}

    // ----- //
    // SWAPS //
    // ----- //

    /// @notice Swaps a token for another token within a single pool
    /// @param singleSwap Struct containing swap parameters
    ///        * `poolId` - ID of the pool to perform a swap in
    ///        * `kind` - type of swap (GIVEN IN / GIVEN OUT)
    ///        * `assetIn` - asset to send
    ///        * `assetOut` - asset to receive
    ///        * `amount` - amount of input asset to send (for GIVEN IN) or output asset to receive (for GIVEN OUT)
    ///        * `userData` - generic blob used to pass extra data
    /// @param limit The minimal amount of `assetOut` to receive or maximal amount of `assetIn` to spend (depending on `kind`)
    /// @param deadline The latest timestamp at which the swap would be executed
    /// @dev `fundManagement` param from the original interface is ignored, as the adapter does not use internal balances and
    ///       only has one sender/recipient
    /// @dev The function reverts if the poolId status is not ALLOWED or SWAP_ONLY
    function swap(SingleSwap memory singleSwap, FundManagement memory, uint256 limit, uint256 deadline)
        external
        override
        creditFacadeOnly // U:[BAL2-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        if (poolStatus[singleSwap.poolId] == PoolStatus.NOT_ALLOWED) {
            revert PoolNotSupportedException(); // U:[BAL2-3]
        }

        address creditAccount = _creditAccount(); // U:[BAL2-3]

        address tokenIn = address(singleSwap.assetIn);
        address tokenOut = address(singleSwap.assetOut);

        FundManagement memory fundManagement = _getDefaultFundManagement(creditAccount); // U:[BAL2-3]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) = _executeSwapSafeApprove(
            tokenIn,
            tokenOut,
            abi.encodeCall(IBalancerV2Vault.swap, (singleSwap, fundManagement, limit, deadline)),
            false
        ); // U:[BAL2-3]
    }

    /// @notice Swaps the entire balance of a token for another token within a single pool, except the specified amount
    /// @param singleSwapDiff Struct containing swap parameters
    ///        * `poolId` - ID of the pool to perform a swap in
    ///        * `leftoverAmount` - amount of assetIn to leave after operation
    ///        * `assetIn` - asset to send
    ///        * `assetOut` - asset to receive
    ///        * `userData` - additional generic blob used to pass extra data
    /// @param limitRateRAY The minimal resulting exchange rate of assetOut to assetIn, scaled by 1e27
    /// @param deadline The latest timestamp at which the swap would be executed
    /// @dev The function reverts if the poolId status is not ALLOWED or SWAP_ONLY
    function swapDiff(SingleSwapDiff memory singleSwapDiff, uint256 limitRateRAY, uint256 deadline)
        external
        override
        creditFacadeOnly // U:[BAL2-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[BAL2-4]

        if (poolStatus[singleSwapDiff.poolId] == PoolStatus.NOT_ALLOWED) {
            revert PoolNotSupportedException(); // U:[BAL2-4]
        }

        uint256 amount = IERC20(address(singleSwapDiff.assetIn)).balanceOf(creditAccount); // U:[BAL2-4]
        if (amount <= singleSwapDiff.leftoverAmount) return (0, 0);

        unchecked {
            amount -= singleSwapDiff.leftoverAmount; // U:[BAL2-4]
        }

        FundManagement memory fundManagement = _getDefaultFundManagement(creditAccount); // U:[BAL2-4]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) = _executeSwapSafeApprove(
            address(singleSwapDiff.assetIn),
            address(singleSwapDiff.assetOut),
            abi.encodeCall(
                IBalancerV2Vault.swap,
                (
                    SingleSwap({
                        poolId: singleSwapDiff.poolId,
                        kind: SwapKind.GIVEN_IN,
                        assetIn: singleSwapDiff.assetIn,
                        assetOut: singleSwapDiff.assetOut,
                        amount: amount,
                        userData: singleSwapDiff.userData
                    }),
                    fundManagement,
                    (amount * limitRateRAY) / RAY,
                    deadline
                )
            ),
            singleSwapDiff.leftoverAmount <= 1
        ); // U:[BAL2-4]
    }

    /// @notice Performs a multi-hop swap through several Balancer pools
    /// @param kind Type of swap (GIVEN IN or GIVEN OUT)
    /// @param swaps Array of structs containing data for each individual swap:
    ///        * `poolId` - ID of the pool to perform a swap in
    ///        * `assetInIndex` - Index of the input asset in the pool (in an alphanumerically sorted array of asset addresses)
    ///        * `assetOutIndex` - Index of the output asset in the pool (in an alphanumerically sorted array of asset addresses)
    ///        * `amount` - amount of asset to send / receive. 0 signals to either spend the entire amount received from the last step,
    ///           or to receive the exact amount needed for the next step
    ///        * `userData` - generic blob used to pass extra data
    /// @param assets Array of all assets participating in the swap
    /// @param limits Array of minimal received (negative) / maximal spent (positive) amounts, in the same order as the assets array
    /// @param deadline The latest timestamp at which the swap would be executed
    /// @dev `fundManagement` param from the original interface is ignored, as the adapter does not use internal balances and
    ///       only has one sender/recipient
    /// @dev The function reverts if any of the poolId statuses is not ALLOWED or SWAP_ONLY
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory,
        int256[] memory limits,
        uint256 deadline
    )
        external
        override
        creditFacadeOnly // U:[BAL2-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        unchecked {
            for (uint256 i; i < swaps.length; ++i) {
                if (poolStatus[swaps[i].poolId] == PoolStatus.NOT_ALLOWED) {
                    revert PoolNotSupportedException(); // U:[BAL2-5]
                }
            }
        }

        address creditAccount = _creditAccount(); // U:[BAL2-5]

        FundManagement memory fundManagement = _getDefaultFundManagement(creditAccount); // U:[BAL2-5]

        _approveAssets(assets, limits, type(uint256).max); // U:[BAL2-5]

        int256[] memory assetDeltas = abi.decode(
            _execute(
                abi.encodeCall(IBalancerV2Vault.batchSwap, (kind, swaps, assets, fundManagement, limits, deadline))
            ),
            (int256[])
        ); // U:[BAL2-5]

        _approveAssets(assets, limits, 1); // U:[BAL2-5]

        (tokensToEnable, tokensToDisable) = (_getTokensToEnable(assets, assetDeltas), 0); // U:[BAL2-5]
    }

    // --------- //
    // JOIN POOL //
    // --------- //

    /// @notice Deposits liquidity into a Balancer pool in exchange for BPT
    /// @param poolId ID of the pool to deposit into
    /// @param request A struct containing data for executing a deposit:
    ///        * `assets` - Array of assets in the pool
    ///        * `maxAmountsIn` - Array of maximal amounts to be spent for each asset
    ///        * `userData` - a blob encoding the type of deposit and additional parameters
    ///          (see https://dev.balancer.fi/resources/joins-and-exits/pool-joins#userdata for more info)
    ///        * `fromInternalBalance` - whether to use internal balances for assets
    ///          (ignored as the adapter does not use internal balances)
    /// @dev `sender` and `recipient` are ignored, since they are always set to the CA address
    /// @dev The function reverts if poolId status is not ALLOWED
    function joinPool(bytes32 poolId, address, address, JoinPoolRequest memory request)
        external
        override
        creditFacadeOnly // U:[BAL2-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        if (poolStatus[poolId] != PoolStatus.ALLOWED) {
            revert PoolNotSupportedException(); // U:[BAL2-6]
        }

        address creditAccount = _creditAccount(); // U:[BAL2-6]

        (address bpt,) = IBalancerV2Vault(targetContract).getPool(poolId);

        request.fromInternalBalance = false; // U:[BAL2-6]

        _approveAssets(request.assets, request.maxAmountsIn, type(uint256).max); // U:[BAL2-6]
        _execute(abi.encodeCall(IBalancerV2Vault.joinPool, (poolId, creditAccount, creditAccount, request))); // U:[BAL2-6]
        _approveAssets(request.assets, request.maxAmountsIn, 1); // U:[BAL2-6]
        (tokensToEnable, tokensToDisable) = (_getMaskOrRevert(bpt), 0); // U:[BAL2-6]
    }

    /// @notice Deposits single asset as liquidity into a Balancer pool
    /// @param poolId ID of the pool to deposit into
    /// @param assetIn Asset to deposit
    /// @param amountIn Amount of asset to deposit
    /// @param minAmountOut The minimal amount of BPT to receive
    /// @dev The function reverts if poolId status is not ALLOWED
    function joinPoolSingleAsset(bytes32 poolId, IAsset assetIn, uint256 amountIn, uint256 minAmountOut)
        external
        override
        creditFacadeOnly // U:[BAL2-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        if (poolStatus[poolId] != PoolStatus.ALLOWED) {
            revert PoolNotSupportedException(); // U:[BAL2-7]
        }

        address creditAccount = _creditAccount(); // U:[BAL2-7]

        (address bpt,) = IBalancerV2Vault(targetContract).getPool(poolId);

        // calling `_executeSwap` because we need to check if BPT is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) = _executeSwapSafeApprove(
            address(assetIn),
            bpt,
            abi.encodeCall(
                IBalancerV2Vault.joinPool,
                (
                    poolId,
                    creditAccount,
                    creditAccount,
                    _getJoinSingleAssetRequest(poolId, assetIn, amountIn, minAmountOut, bpt)
                )
            ),
            false
        ); // U:[BAL2-7]
    }

    /// @notice Deposits the entire balance of given asset, except a specified amount, as liquidity into a Balancer pool
    /// @param poolId ID of the pool to deposit into
    /// @param assetIn Asset to deposit
    /// @param leftoverAmount Amount of underlying to keep on the account
    /// @param minRateRAY The minimal exchange rate of assetIn to BPT, scaled by 1e27
    /// @dev The function reverts if poolId status is not ALLOWED
    function joinPoolSingleAssetDiff(bytes32 poolId, IAsset assetIn, uint256 leftoverAmount, uint256 minRateRAY)
        external
        override
        creditFacadeOnly // U:[BAL2-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[BAL2-8]

        if (poolStatus[poolId] != PoolStatus.ALLOWED) {
            revert PoolNotSupportedException(); // U:[BAL2-8]
        }

        uint256 amount = IERC20(address(assetIn)).balanceOf(creditAccount); // U:[BAL2-8]
        if (amount <= leftoverAmount) return (0, 0);

        unchecked {
            amount -= leftoverAmount; // U:[BAL2-8]
        }

        (address bpt,) = IBalancerV2Vault(targetContract).getPool(poolId);

        uint256 amountOutMin = (amount * minRateRAY) / RAY; // U:[BAL2-8]
        JoinPoolRequest memory request = _getJoinSingleAssetRequest(poolId, assetIn, amount, amountOutMin, bpt); // U:[BAL2-8]

        // calling `_executeSwap` because we need to check if BPT is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) = _executeSwapSafeApprove(
            address(assetIn),
            bpt,
            abi.encodeCall(IBalancerV2Vault.joinPool, (poolId, creditAccount, creditAccount, request)),
            leftoverAmount <= 1
        ); // U:[BAL2-8]
    }

    /// @dev Internal function that builds a `JoinPoolRequest` struct for one-sided deposits
    function _getJoinSingleAssetRequest(
        bytes32 poolId,
        IAsset assetIn,
        uint256 amountIn,
        uint256 minAmountOut,
        address bpt
    ) internal view returns (JoinPoolRequest memory request) {
        (IERC20[] memory tokens,,) = IBalancerV2Vault(targetContract).getPoolTokens(poolId);

        uint256 len = tokens.length;

        request.assets = new IAsset[](tokens.length);
        request.maxAmountsIn = new uint256[](tokens.length);
        uint256 bptIndex = tokens.length;

        unchecked {
            for (uint256 i; i < len; ++i) {
                request.assets[i] = IAsset(address(tokens[i]));

                if (request.assets[i] == assetIn) {
                    request.maxAmountsIn[i] = amountIn; // U:[BAL2-7,8]
                }

                if (address(request.assets[i]) == bpt) {
                    bptIndex = i;
                }
            }
        }

        request.userData = abi.encode(uint256(1), _removeIndex(request.maxAmountsIn, bptIndex), minAmountOut); // U:[BAL2-7,8]
    }

    // --------- //
    // EXIT POOL //
    // --------- //

    /// @notice Withdraws liquidity from a Balancer pool, burning BPT and receiving assets
    /// @param poolId ID of the pool to withdraw from
    /// @param request A struct containing data for executing a withdrawal:
    ///        * `assets` - Array of all assets in the pool
    ///        * `minAmountsOut` - The minimal amounts to receive for each asset
    ///        * `userData` - a blob encoding the type of deposit and additional parameters
    ///          (see https://dev.balancer.fi/resources/joins-and-exits/pool-exits#userdata for more info)
    ///        * `toInternalBalance` - whether to use internal balances for assets
    ///          (ignored as the adapter does not use internal balances)
    /// @dev `sender` and `recipient` are ignored, since they are always set to the CA address
    function exitPool(bytes32 poolId, address, address payable, ExitPoolRequest memory request)
        external
        override
        creditFacadeOnly // U:[BAL2-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[BAL2-9]

        (address bpt,) = IBalancerV2Vault(targetContract).getPool(poolId);

        request.toInternalBalance = false; // U:[BAL2-9]

        _execute(abi.encodeCall(IBalancerV2Vault.exitPool, (poolId, creditAccount, payable(creditAccount), request))); // U:[BAL2-9]

        _getMaskOrRevert(bpt); // U:[BAL2-9]
        (tokensToEnable, tokensToDisable) =
            (_getTokensToEnable(request.assets, _getBalancesFilter(creditAccount, request.assets)), 0); // U:[BAL2-9]
    }

    /// @notice Withdraws liquidity from a Balancer pool, burning BPT and receiving a single asset
    /// @param poolId ID of the pool to withdraw from
    /// @param assetOut Asset to withdraw
    /// @param amountIn Amount of BPT to burn
    /// @param minAmountOut Minimal amount of asset to receive
    function exitPoolSingleAsset(bytes32 poolId, IAsset assetOut, uint256 amountIn, uint256 minAmountOut)
        external
        override
        creditFacadeOnly // U:[BAL2-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[BAL2-10]

        (address bpt,) = IBalancerV2Vault(targetContract).getPool(poolId);

        // calling `_executeSwap` because we need to check if asset is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) = _executeSwapNoApprove(
            bpt,
            address(assetOut),
            abi.encodeCall(
                IBalancerV2Vault.exitPool,
                (
                    poolId,
                    creditAccount,
                    payable(creditAccount),
                    _getExitSingleAssetRequest(poolId, assetOut, amountIn, minAmountOut, bpt)
                )
            ),
            false
        ); // U:[BAL2-10]
    }

    /// @notice Withdraws all liquidity from a Balancer pool except the specified amount, burning BPT and receiving a single asset
    /// @param poolId ID of the pool to withdraw from
    /// @param assetOut Asset to withdraw
    /// @param leftoverAmount Amount of pool token to keep on the account
    /// @param minRateRAY Minimal exchange rate of BPT to assetOut, scaled by 1e27
    function exitPoolSingleAssetDiff(bytes32 poolId, IAsset assetOut, uint256 leftoverAmount, uint256 minRateRAY)
        external
        override
        creditFacadeOnly // U:[BAL2-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[BAL2-11]

        (address bpt,) = IBalancerV2Vault(targetContract).getPool(poolId);

        uint256 amount = IERC20(bpt).balanceOf(creditAccount); // U:[BAL2-11]
        if (amount <= leftoverAmount) return (0, 0);

        unchecked {
            amount -= leftoverAmount; // U:[BAL2-11]
        }

        uint256 amountOutMin = (amount * minRateRAY) / RAY; // U:[BAL2-11]
        ExitPoolRequest memory request = _getExitSingleAssetRequest(poolId, assetOut, amount, amountOutMin, bpt); // U:[BAL2-11]

        // calling `_executeSwap` because we need to check if asset is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) = _executeSwapNoApprove(
            bpt,
            address(assetOut),
            abi.encodeCall(IBalancerV2Vault.exitPool, (poolId, creditAccount, payable(creditAccount), request)),
            leftoverAmount <= 1
        ); // U:[BAL2-11]
    }

    /// @dev Internal function that builds an `ExitPoolRequest` struct for one-sided withdrawals
    function _getExitSingleAssetRequest(
        bytes32 poolId,
        IAsset assetOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address bpt
    ) internal view returns (ExitPoolRequest memory request) {
        (IERC20[] memory tokens,,) = IBalancerV2Vault(targetContract).getPoolTokens(poolId);

        uint256 len = tokens.length;

        request.assets = new IAsset[](tokens.length);
        request.minAmountsOut = new uint256[](tokens.length);
        uint256 tokenIndex = tokens.length;
        uint256 bptIndex = tokens.length;

        unchecked {
            for (uint256 i; i < len; ++i) {
                request.assets[i] = IAsset(address(tokens[i]));

                if (request.assets[i] == assetOut) {
                    request.minAmountsOut[i] = minAmountOut; // U:[BAL2-10,11]
                    tokenIndex = i;
                }

                if (address(request.assets[i]) == bpt) {
                    bptIndex = i;
                }
            }
        }

        tokenIndex = tokenIndex > bptIndex ? tokenIndex - 1 : tokenIndex; // U:[BAL2-10,11]

        request.userData = abi.encode(uint256(0), amountIn, tokenIndex);
    }

    // ------- //
    // HELPERS //
    // ------- //

    /// @dev Internal function that changes approval for a batch of assets in the vault
    function _approveAssets(IAsset[] memory assets, int256[] memory filter, uint256 amount) internal {
        uint256 len = assets.length;

        unchecked {
            for (uint256 i; i < len; ++i) {
                if (filter[i] > 1) _approveToken(address(assets[i]), amount);
            }
        }
    }

    /// @dev Internal function that changes approval for a batch of assets in the vault (overloading)
    function _approveAssets(IAsset[] memory assets, uint256[] memory filter, uint256 amount) internal {
        uint256 len = assets.length;

        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                if (filter[i] > 1) _approveToken(address(assets[i]), amount);
            }
        }
    }

    /// @dev Returns mask of all tokens that should be enabled, based on balances / balance changes
    function _getTokensToEnable(IAsset[] memory assets, int256[] memory filter)
        internal
        view
        returns (uint256 tokensToEnable)
    {
        uint256 len = assets.length;

        unchecked {
            for (uint256 i; i < len; ++i) {
                if (filter[i] < -1) tokensToEnable = tokensToEnable.enable(_getMaskOrRevert(address(assets[i])));
            }
        }
    }

    /// @dev Internal function that creates a filter based on CA token balances
    function _getBalancesFilter(address creditAccount, IAsset[] memory assets)
        internal
        view
        returns (int256[] memory filter)
    {
        uint256 len = assets.length;

        filter = new int256[](len);

        for (uint256 i = 0; i < len;) {
            filter[i] = -int256(IERC20(address(assets[i])).balanceOf(creditAccount));
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Returns a standard `FundManagement` struct used by the adapter
    function _getDefaultFundManagement(address creditAccount) internal pure returns (FundManagement memory) {
        return FundManagement({
            sender: creditAccount,
            fromInternalBalance: false,
            recipient: payable(creditAccount),
            toInternalBalance: false
        });
    }

    /// @dev Returns copy of `array` without an element at `index`
    function _removeIndex(uint256[] memory array, uint256 index) internal pure returns (uint256[] memory res) {
        uint256 len = array.length;

        if (index >= len) {
            return array;
        }

        len = len - 1;

        res = new uint256[](len);

        for (uint256 i = 0; i < len;) {
            if (i < index) {
                res[i] = array[i];
            } else {
                res[i] = array[i + 1];
            }

            unchecked {
                ++i;
            }
        }
    }

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Sets the pool status
    function setPoolStatus(bytes32 poolId, PoolStatus newStatus)
        external
        override
        configuratorOnly // U:[BAL2-12]
    {
        if (poolStatus[poolId] != newStatus) {
            poolStatus[poolId] = newStatus; // U:[BAL2-12]
            emit SetPoolStatus(poolId, newStatus); // U:[BAL2-12]
        }
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

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// Denominations

uint256 constant WAD = 1e18;
uint256 constant RAY = 1e27;
uint16 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals

// 25% of type(uint256).max
uint256 constant ALLOWANCE_THRESHOLD = type(uint96).max >> 3;

// FEE = 50%
uint16 constant DEFAULT_FEE_INTEREST = 50_00; // 50%

// LIQUIDATION_FEE 1.5%
uint16 constant DEFAULT_FEE_LIQUIDATION = 1_50; // 1.5%

// LIQUIDATION PREMIUM 4%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM = 4_00; // 4%

// LIQUIDATION_FEE_EXPIRED 2%
uint16 constant DEFAULT_FEE_LIQUIDATION_EXPIRED = 1_00; // 2%

// LIQUIDATION PREMIUM EXPIRED 2%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM_EXPIRED = 2_00; // 2%

// DEFAULT PROPORTION OF MAX BORROWED PER BLOCK TO MAX BORROWED PER ACCOUNT
uint16 constant DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 2;

// Seconds in a year
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = (SECONDS_PER_YEAR * 3) / 2;

// OPERATIONS

// Leverage decimals - 100 is equal to 2x leverage (100% * collateral amount + 100% * borrowed amount)
uint8 constant LEVERAGE_DECIMALS = 100;

// Maximum withdraw fee for pool in PERCENTAGE_FACTOR format
uint8 constant MAX_WITHDRAW_FEE = 100;

uint256 constant EXACT_INPUT = 1;
uint256 constant EXACT_OUTPUT = 2;

address constant UNIVERSAL_CONTRACT = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IncorrectParameterException} from "../interfaces/IExceptions.sol";

uint256 constant UNDERLYING_TOKEN_MASK = 1;

/// @title Bit mask library
/// @notice Implements functions that manipulate bit masks
///         Bit masks are utilized extensively by Gearbox to efficiently store token sets (enabled tokens on accounts
///         or forbidden tokens) and check for set inclusion. A mask is a uint256 number that has its i-th bit set to
///         1 if i-th item is included into the set. For example, each token has a mask equal to 2**i, so set inclusion
///         can be checked by checking tokenMask & setMask != 0.
library BitMask {
    /// @dev Calculates an index of an item based on its mask (using a binary search)
    /// @dev The input should always have only 1 bit set, otherwise the result may be unpredictable
    function calcIndex(uint256 mask) internal pure returns (uint8 index) {
        if (mask == 0) revert IncorrectParameterException(); // U:[BM-1]
        uint16 lb = 0; // U:[BM-2]
        uint16 ub = 256; // U:[BM-2]
        uint16 mid = 128; // U:[BM-2]

        unchecked {
            while (true) {
                uint256 newMask = 1 << mid;
                if (newMask & mask != 0) return uint8(mid); // U:[BM-2]

                if (newMask > mask) ub = mid; // U:[BM-2]

                else lb = mid; // U:[BM-2]
                mid = (lb + ub) >> 1; // U:[BM-2]
            }
        }
    }

    /// @dev Calculates the number of `1` bits
    /// @param enabledTokensMask Bit mask to compute the number of `1` bits in
    function calcEnabledTokens(uint256 enabledTokensMask) internal pure returns (uint256 totalTokensEnabled) {
        unchecked {
            while (enabledTokensMask > 0) {
                enabledTokensMask &= enabledTokensMask - 1; // U:[BM-3]
                ++totalTokensEnabled; // U:[BM-3]
            }
        }
    }

    /// @dev Enables bits from the second mask in the first mask
    /// @param enabledTokenMask The initial mask
    /// @param bitsToEnable Mask of bits to enable
    function enable(uint256 enabledTokenMask, uint256 bitsToEnable) internal pure returns (uint256) {
        return enabledTokenMask | bitsToEnable; // U:[BM-4]
    }

    /// @dev Disables bits from the second mask in the first mask
    /// @param enabledTokenMask The initial mask
    /// @param bitsToDisable Mask of bits to disable
    function disable(uint256 enabledTokenMask, uint256 bitsToDisable) internal pure returns (uint256) {
        return enabledTokenMask & ~bitsToDisable; // U:[BM-4]
    }

    /// @dev Computes a new mask with sets of new enabled and disabled bits
    /// @dev bitsToEnable and bitsToDisable are applied sequentially to original mask
    /// @param enabledTokensMask The initial mask
    /// @param bitsToEnable Mask with bits to enable
    /// @param bitsToDisable Mask with bits to disable
    function enableDisable(uint256 enabledTokensMask, uint256 bitsToEnable, uint256 bitsToDisable)
        internal
        pure
        returns (uint256)
    {
        return (enabledTokensMask | bitsToEnable) & (~bitsToDisable); // U:[BM-5]
    }

    /// @dev Enables bits from the second mask in the first mask, skipping specified bits
    /// @param enabledTokenMask The initial mask
    /// @param bitsToEnable Mask with bits to enable
    /// @param invertedSkipMask An inversion of mask of immutable bits
    function enable(uint256 enabledTokenMask, uint256 bitsToEnable, uint256 invertedSkipMask)
        internal
        pure
        returns (uint256)
    {
        return enabledTokenMask | (bitsToEnable & invertedSkipMask); // U:[BM-6]
    }

    /// @dev Disables bits from the second mask in the first mask, skipping specified bits
    /// @param enabledTokenMask The initial mask
    /// @param bitsToDisable Mask with bits to disable
    /// @param invertedSkipMask An inversion of mask of immutable bits
    function disable(uint256 enabledTokenMask, uint256 bitsToDisable, uint256 invertedSkipMask)
        internal
        pure
        returns (uint256)
    {
        return enabledTokenMask & (~(bitsToDisable & invertedSkipMask)); // U:[BM-6]
    }

    /// @dev Computes a new mask with sets of new enabled and disabled bits, skipping some bits
    /// @dev bitsToEnable and bitsToDisable are applied sequentially to original mask. Skipmask is applied in both cases.
    /// @param enabledTokensMask The initial mask
    /// @param bitsToEnable Mask with bits to enable
    /// @param bitsToDisable Mask with bits to disable
    /// @param invertedSkipMask An inversion of mask of immutable bits
    function enableDisable(
        uint256 enabledTokensMask,
        uint256 bitsToEnable,
        uint256 bitsToDisable,
        uint256 invertedSkipMask
    ) internal pure returns (uint256) {
        return (enabledTokensMask | (bitsToEnable & invertedSkipMask)) & (~(bitsToDisable & invertedSkipMask)); // U:[BM-7]
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IAdapter} from "@gearbox-protocol/core-v2/contracts/interfaces/IAdapter.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {CallerNotCreditFacadeException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";
import {ACLTrait} from "@gearbox-protocol/core-v3/contracts/traits/ACLTrait.sol";

/// @title Abstract adapter
/// @dev Inheriting adapters MUST use provided internal functions to perform all operations with credit accounts
abstract contract AbstractAdapter is IAdapter, ACLTrait {
    /// @notice Credit manager the adapter is connected to
    address public immutable override creditManager;

    /// @notice Address provider contract
    address public immutable override addressProvider;

    /// @notice Address of the contract the adapter is interacting with
    address public immutable override targetContract;

    /// @notice Constructor
    /// @param _creditManager Credit manager to connect the adapter to
    /// @param _targetContract Address of the adapted contract
    constructor(address _creditManager, address _targetContract)
        ACLTrait(ICreditManagerV3(_creditManager).addressProvider())
        nonZeroAddress(_targetContract)
    {
        creditManager = _creditManager;
        addressProvider = ICreditManagerV3(_creditManager).addressProvider();
        targetContract = _targetContract;
    }

    /// @dev Ensures that caller of the function is credit facade connected to the credit manager
    /// @dev Inheriting adapters MUST use this modifier in all external functions that operate on credit accounts
    modifier creditFacadeOnly() {
        _revertIfCallerNotCreditFacade();
        _;
    }

    /// @dev Ensures that caller is credit facade connected to the credit manager
    function _revertIfCallerNotCreditFacade() internal view {
        if (msg.sender != ICreditManagerV3(creditManager).creditFacade()) {
            revert CallerNotCreditFacadeException();
        }
    }

    /// @dev Ensures that active credit account is set and returns its address
    function _creditAccount() internal view returns (address) {
        return ICreditManagerV3(creditManager).getActiveCreditAccountOrRevert();
    }

    /// @dev Ensures that token is registered as collateral in the credit manager and returns its mask
    function _getMaskOrRevert(address token) internal view returns (uint256 tokenMask) {
        tokenMask = ICreditManagerV3(creditManager).getTokenMaskOrRevert(token);
    }

    /// @dev Approves target contract to spend given token from the active credit account
    ///      Reverts if active credit account is not set or token is not registered as collateral
    /// @param token Token to approve
    /// @param amount Amount to approve
    function _approveToken(address token, uint256 amount) internal {
        ICreditManagerV3(creditManager).approveCreditAccount(token, amount);
    }

    /// @dev Executes an external call from the active credit account to the target contract
    ///      Reverts if active credit account is not set
    /// @param callData Data to call the target contract with
    /// @return result Call result
    function _execute(bytes memory callData) internal returns (bytes memory result) {
        return ICreditManagerV3(creditManager).execute(callData);
    }

    /// @dev Executes a swap operation without input token approval
    ///      Reverts if active credit account is not set or any of passed tokens is not registered as collateral
    /// @param tokenIn Input token that credit account spends in the call
    /// @param tokenOut Output token that credit account receives after the call
    /// @param callData Data to call the target contract with
    /// @param disableTokenIn Whether `tokenIn` should be disabled after the call
    ///        (for operations that spend the entire account's balance of the input token)
    /// @return tokensToEnable Bit mask of tokens that should be enabled after the call
    /// @return tokensToDisable Bit mask of tokens that should be disabled after the call
    /// @return result Call result
    function _executeSwapNoApprove(address tokenIn, address tokenOut, bytes memory callData, bool disableTokenIn)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable, bytes memory result)
    {
        tokensToEnable = _getMaskOrRevert(tokenOut);
        uint256 tokenInMask = _getMaskOrRevert(tokenIn);
        if (disableTokenIn) tokensToDisable = tokenInMask;
        result = _execute(callData);
    }

    /// @dev Executes a swap operation with maximum input token approval, and revokes approval after the call
    ///      Reverts if active credit account is not set or any of passed tokens is not registered as collateral
    /// @param tokenIn Input token that credit account spends in the call
    /// @param tokenOut Output token that credit account receives after the call
    /// @param callData Data to call the target contract with
    /// @param disableTokenIn Whether `tokenIn` should be disabled after the call
    ///        (for operations that spend the entire account's balance of the input token)
    /// @return tokensToEnable Bit mask of tokens that should be enabled after the call
    /// @return tokensToDisable Bit mask of tokens that should be disabled after the call
    /// @return result Call result
    /// @custom:expects Credit manager reverts when trying to approve non-collateral token
    function _executeSwapSafeApprove(address tokenIn, address tokenOut, bytes memory callData, bool disableTokenIn)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable, bytes memory result)
    {
        tokensToEnable = _getMaskOrRevert(tokenOut);
        if (disableTokenIn) tokensToDisable = _getMaskOrRevert(tokenIn);
        _approveToken(tokenIn, type(uint256).max);
        result = _execute(callData);
        _approveToken(tokenIn, 1);
    }
}

// SPDX-License-Identifier: UNLICENSED
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox Foundation, 2023
pragma solidity ^0.8.17;

enum AdapterType {
    ABSTRACT,
    UNISWAP_V2_ROUTER,
    UNISWAP_V3_ROUTER,
    CURVE_V1_EXCHANGE_ONLY,
    YEARN_V2,
    CURVE_V1_2ASSETS,
    CURVE_V1_3ASSETS,
    CURVE_V1_4ASSETS,
    CURVE_V1_STECRV_POOL,
    CURVE_V1_WRAPPER,
    CONVEX_V1_BASE_REWARD_POOL,
    CONVEX_V1_BOOSTER,
    CONVEX_V1_CLAIM_ZAP,
    LIDO_V1,
    UNIVERSAL,
    LIDO_WSTETH_V1,
    BALANCER_VAULT,
    AAVE_V2_LENDING_POOL,
    AAVE_V2_WRAPPED_ATOKEN,
    COMPOUND_V2_CERC20,
    COMPOUND_V2_CETHER,
    ERC4626_VAULT,
    VELODROME_V2_ROUTER,
    CURVE_STABLE_NG,
    CAMELOT_V3_ROUTER,
    CONVEX_L2_BOOSTER,
    CONVEX_L2_REWARD_POOL,
    AAVE_V3_LENDING_POOL
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
// solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAsset} from "./IAsset.sol";

enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}

enum PoolSpecialization {
    GENERAL,
    MINIMAL_SWAP_INFO,
    TWO_TOKEN
}

enum JoinKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT,
    TOKEN_IN_FOR_EXACT_BPT_OUT,
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
}

enum ExitKind {
    EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT,
    BPT_IN_FOR_EXACT_TOKENS_OUT
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
}

struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}

struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}

interface IBalancerV2VaultGetters {
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
}

interface IBalancerV2Vault is IBalancerV2VaultGetters {
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external returns (int256[] memory assetDeltas);

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        returns (uint256 amountCalculated);

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external;

    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request)
        external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IAdapter} from "@gearbox-protocol/core-v2/contracts/interfaces/IAdapter.sol";

import {
    IAsset,
    SingleSwap,
    FundManagement,
    SwapKind,
    BatchSwapStep,
    JoinPoolRequest,
    ExitPoolRequest
} from "../../integrations/balancer/IBalancerV2Vault.sol";

enum PoolStatus {
    NOT_ALLOWED,
    ALLOWED,
    SWAP_ONLY
}

struct SingleSwapDiff {
    bytes32 poolId;
    uint256 leftoverAmount;
    IAsset assetIn;
    IAsset assetOut;
    bytes userData;
}

interface IBalancerV2VaultAdapterEvents {
    /// @notice Emitted when new status is set for a pool with given ID
    event SetPoolStatus(bytes32 indexed poolId, PoolStatus newStatus);
}

interface IBalancerV2VaultAdapterExceptions {
    /// @notice Thrown when attempting to swap or change liqudity in the pool that is not supported for that action
    error PoolNotSupportedException();
}

/// @title Balancer V2 Vault adapter interface
interface IBalancerV2VaultAdapter is IAdapter, IBalancerV2VaultAdapterEvents, IBalancerV2VaultAdapterExceptions {
    // ----- //
    // SWAPS //
    // ----- //

    function swap(SingleSwap memory singleSwap, FundManagement memory, uint256 limit, uint256 deadline)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function swapDiff(SingleSwapDiff memory singleSwapDiff, uint256 limitRateRAY, uint256 deadline)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory,
        int256[] memory limits,
        uint256 deadline
    ) external returns (uint256 tokensToEnable, uint256 tokensToDisable);

    // --------- //
    // JOIN POOL //
    // --------- //

    function joinPool(bytes32 poolId, address, address, JoinPoolRequest memory request)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function joinPoolSingleAsset(bytes32 poolId, IAsset assetIn, uint256 amountIn, uint256 minAmountOut)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function joinPoolSingleAssetDiff(bytes32 poolId, IAsset assetIn, uint256 leftoverAmount, uint256 minRateRAY)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    // --------- //
    // EXIT POOL //
    // --------- //

    function exitPool(bytes32 poolId, address, address payable, ExitPoolRequest memory request)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exitPoolSingleAsset(bytes32 poolId, IAsset assetOut, uint256 amountIn, uint256 minAmountOut)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exitPoolSingleAssetDiff(bytes32 poolId, IAsset assetOut, uint256 leftoverAmount, uint256 minRateRAY)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function poolStatus(bytes32 poolId) external view returns (PoolStatus);

    function setPoolStatus(bytes32 poolId, PoolStatus newStatus) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// ------- //
// GENERAL //
// ------- //

/// @notice Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @notice Thrown when attempting to pass a zero amount to a funding-related operation
error AmountCantBeZeroException();

/// @notice Thrown on incorrect input parameter
error IncorrectParameterException();

/// @notice Thrown when balance is insufficient to perform an operation
error InsufficientBalanceException();

/// @notice Thrown if parameter is out of range
error ValueOutOfRangeException();

/// @notice Thrown when trying to send ETH to a contract that is not allowed to receive ETH directly
error ReceiveIsNotAllowedException();

/// @notice Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @notice Thrown on attempting to receive a token that is not a collateral token or was forbidden
error TokenNotAllowedException();

/// @notice Thrown on attempting to add a token that is already in a collateral list
error TokenAlreadyAddedException();

/// @notice Thrown when attempting to use quota-related logic for a token that is not quoted in quota keeper
error TokenIsNotQuotedException();

/// @notice Thrown on attempting to interact with an address that is not a valid target contract
error TargetContractNotAllowedException();

/// @notice Thrown if function is not implemented
error NotImplementedException();

// ------------------ //
// CONTRACTS REGISTER //
// ------------------ //

/// @notice Thrown when an address is expected to be a registered credit manager, but is not
error RegisteredCreditManagerOnlyException();

/// @notice Thrown when an address is expected to be a registered pool, but is not
error RegisteredPoolOnlyException();

// ---------------- //
// ADDRESS PROVIDER //
// ---------------- //

/// @notice Reverts if address key isn't found in address provider
error AddressNotFoundException();

// ----------------- //
// POOL, PQK, GAUGES //
// ----------------- //

/// @notice Thrown by pool-adjacent contracts when a credit manager being connected has a wrong pool address
error IncompatibleCreditManagerException();

/// @notice Thrown when attempting to set an incompatible successor staking contract
error IncompatibleSuccessorException();

/// @notice Thrown when attempting to vote in a non-approved contract
error VotingContractNotAllowedException();

/// @notice Thrown when attempting to unvote more votes than there are
error InsufficientVotesException();

/// @notice Thrown when attempting to borrow more than the second point on a two-point curve
error BorrowingMoreThanU2ForbiddenException();

/// @notice Thrown when a credit manager attempts to borrow more than its limit in the current block, or in general
error CreditManagerCantBorrowException();

/// @notice Thrown when attempting to connect a quota keeper to an incompatible pool
error IncompatiblePoolQuotaKeeperException();

/// @notice Thrown when the quota is outside of min/max bounds
error QuotaIsOutOfBoundsException();

// -------------- //
// CREDIT MANAGER //
// -------------- //

/// @notice Thrown on failing a full collateral check after multicall
error NotEnoughCollateralException();

/// @notice Thrown if an attempt to approve a collateral token to adapter's target contract fails
error AllowanceFailedException();

/// @notice Thrown on attempting to perform an action for a credit account that does not exist
error CreditAccountDoesNotExistException();

/// @notice Thrown on configurator attempting to add more than 255 collateral tokens
error TooManyTokensException();

/// @notice Thrown if more than the maximum number of tokens were enabled on a credit account
error TooManyEnabledTokensException();

/// @notice Thrown when attempting to execute a protocol interaction without active credit account set
error ActiveCreditAccountNotSetException();

/// @notice Thrown when trying to update credit account's debt more than once in the same block
error DebtUpdatedTwiceInOneBlockException();

/// @notice Thrown when trying to repay all debt while having active quotas
error DebtToZeroWithActiveQuotasException();

/// @notice Thrown when a zero-debt account attempts to update quota
error UpdateQuotaOnZeroDebtAccountException();

/// @notice Thrown when attempting to close an account with non-zero debt
error CloseAccountWithNonZeroDebtException();

/// @notice Thrown when value of funds remaining on the account after liquidation is insufficient
error InsufficientRemainingFundsException();

/// @notice Thrown when Credit Facade tries to write over a non-zero active Credit Account
error ActiveCreditAccountOverridenException();

// ------------------- //
// CREDIT CONFIGURATOR //
// ------------------- //

/// @notice Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @notice Thrown if the newly set LT if zero or greater than the underlying's LT
error IncorrectLiquidationThresholdException();

/// @notice Thrown if borrowing limits are incorrect: minLimit > maxLimit or maxLimit > blockLimit
error IncorrectLimitsException();

/// @notice Thrown if the new expiration date is less than the current expiration date or current timestamp
error IncorrectExpirationDateException();

/// @notice Thrown if a contract returns a wrong credit manager or reverts when trying to retrieve it
error IncompatibleContractException();

/// @notice Thrown if attempting to forbid an adapter that is not registered in the credit manager
error AdapterIsNotRegisteredException();

// ------------- //
// CREDIT FACADE //
// ------------- //

/// @notice Thrown when attempting to perform an action that is forbidden in whitelisted mode
error ForbiddenInWhitelistedModeException();

/// @notice Thrown if credit facade is not expirable, and attempted aciton requires expirability
error NotAllowedWhenNotExpirableException();

/// @notice Thrown if a selector that doesn't match any allowed function is passed to the credit facade in a multicall
error UnknownMethodException();

/// @notice Thrown when trying to close an account with enabled tokens
error CloseAccountWithEnabledTokensException();

/// @notice Thrown if a liquidator tries to liquidate an account with a health factor above 1
error CreditAccountNotLiquidatableException();

/// @notice Thrown if too much new debt was taken within a single block
error BorrowedBlockLimitException();

/// @notice Thrown if the new debt principal for a credit account falls outside of borrowing limits
error BorrowAmountOutOfLimitsException();

/// @notice Thrown if a user attempts to open an account via an expired credit facade
error NotAllowedAfterExpirationException();

/// @notice Thrown if expected balances are attempted to be set twice without performing a slippage check
error ExpectedBalancesAlreadySetException();

/// @notice Thrown if attempting to perform a slippage check when excepted balances are not set
error ExpectedBalancesNotSetException();

/// @notice Thrown if balance of at least one token is less than expected during a slippage check
error BalanceLessThanExpectedException();

/// @notice Thrown when trying to perform an action that is forbidden when credit account has enabled forbidden tokens
error ForbiddenTokensException();

/// @notice Thrown when new forbidden tokens are enabled during the multicall
error ForbiddenTokenEnabledException();

/// @notice Thrown when enabled forbidden token balance is increased during the multicall
error ForbiddenTokenBalanceIncreasedException();

/// @notice Thrown when the remaining token balance is increased during the liquidation
error RemainingTokenBalanceIncreasedException();

/// @notice Thrown if `botMulticall` is called by an address that is not approved by account owner or is forbidden
error NotApprovedBotException();

/// @notice Thrown when attempting to perform a multicall action with no permission for it
error NoPermissionException(uint256 permission);

/// @notice Thrown when attempting to give a bot unexpected permissions
error UnexpectedPermissionsException();

/// @notice Thrown when a custom HF parameter lower than 10000 is passed into the full collateral check
error CustomHealthFactorTooLowException();

/// @notice Thrown when submitted collateral hint is not a valid token mask
error InvalidCollateralHintException();

// ------ //
// ACCESS //
// ------ //

/// @notice Thrown on attempting to call an access restricted function not as credit account owner
error CallerNotCreditAccountOwnerException();

/// @notice Thrown on attempting to call an access restricted function not as configurator
error CallerNotConfiguratorException();

/// @notice Thrown on attempting to call an access-restructed function not as account factory
error CallerNotAccountFactoryException();

/// @notice Thrown on attempting to call an access restricted function not as credit manager
error CallerNotCreditManagerException();

/// @notice Thrown on attempting to call an access restricted function not as credit facade
error CallerNotCreditFacadeException();

/// @notice Thrown on attempting to call an access restricted function not as controller or configurator
error CallerNotControllerException();

/// @notice Thrown on attempting to pause a contract without pausable admin rights
error CallerNotPausableAdminException();

/// @notice Thrown on attempting to unpause a contract without unpausable admin rights
error CallerNotUnpausableAdminException();

/// @notice Thrown on attempting to call an access restricted function not as gauge
error CallerNotGaugeException();

/// @notice Thrown on attempting to call an access restricted function not as quota keeper
error CallerNotPoolQuotaKeeperException();

/// @notice Thrown on attempting to call an access restricted function not as voter
error CallerNotVoterException();

/// @notice Thrown on attempting to call an access restricted function not as allowed adapter
error CallerNotAdapterException();

/// @notice Thrown on attempting to call an access restricted function not as migrator
error CallerNotMigratorException();

/// @notice Thrown when an address that is not the designated executor attempts to execute a transaction
error CallerNotExecutorException();

/// @notice Thrown on attempting to call an access restricted function not as veto admin
error CallerNotVetoAdminException();

// ------------------- //
// CONTROLLER TIMELOCK //
// ------------------- //

/// @notice Thrown when the new parameter values do not satisfy required conditions
error ParameterChecksFailedException();

/// @notice Thrown when attempting to execute a non-queued transaction
error TxNotQueuedException();

/// @notice Thrown when attempting to execute a transaction that is either immature or stale
error TxExecutedOutsideTimeWindowException();

/// @notice Thrown when execution of a transaction fails
error TxExecutionRevertedException();

/// @notice Thrown when the value of a parameter on execution is different from the value on queue
error ParameterChangedAfterQueuedTxException();

// -------- //
// BOT LIST //
// -------- //

/// @notice Thrown when attempting to set non-zero permissions for a forbidden or special bot
error InvalidBotException();

// --------------- //
// ACCOUNT FACTORY //
// --------------- //

/// @notice Thrown when trying to deploy second master credit account for a credit manager
error MasterCreditAccountAlreadyDeployedException();

/// @notice Thrown when trying to rescue funds from a credit account that is currently in use
error CreditAccountIsInUseException();

// ------------ //
// PRICE ORACLE //
// ------------ //

/// @notice Thrown on attempting to set a token price feed to an address that is not a correct price feed
error IncorrectPriceFeedException();

/// @notice Thrown on attempting to interact with a price feed for a token not added to the price oracle
error PriceFeedDoesNotExistException();

/// @notice Thrown when price feed returns incorrect price for a token
error IncorrectPriceException();

/// @notice Thrown when token's price feed becomes stale
error StalePriceException();

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.0;

import { AdapterType } from "@gearbox-protocol/sdk-gov/contracts/AdapterType.sol";

/// @title Adapter interface
interface IAdapter {
    function _gearboxAdapterType() external view returns (AdapterType);

    function _gearboxAdapterVersion() external view returns (uint16);

    function creditManager() external view returns (address);

    function addressProvider() external view returns (address);

    function targetContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

uint8 constant BOT_PERMISSIONS_SET_FLAG = 1;

uint8 constant DEFAULT_MAX_ENABLED_TOKENS = 4;
address constant INACTIVE_CREDIT_ACCOUNT_ADDRESS = address(1);

/// @notice Debt management type
///         - `INCREASE_DEBT` borrows additional funds from the pool, updates account's debt and cumulative interest index
///         - `DECREASE_DEBT` repays debt components (quota interest and fees -> base interest and fees -> debt principal)
///           and updates all corresponding state varibles (base interest index, quota interest and fees, debt).
///           When repaying all the debt, ensures that account has no enabled quotas.
enum ManageDebtAction {
    INCREASE_DEBT,
    DECREASE_DEBT
}

/// @notice Collateral/debt calculation mode
///         - `GENERIC_PARAMS` returns generic data like account debt and cumulative indexes
///         - `DEBT_ONLY` is same as `GENERIC_PARAMS` but includes more detailed debt info, like accrued base/quota
///           interest and fees
///         - `FULL_COLLATERAL_CHECK_LAZY` checks whether account is sufficiently collateralized in a lazy fashion,
///           i.e. it stops iterating over collateral tokens once TWV reaches the desired target.
///           Since it may return underestimated TWV, it's only available for internal use.
///         - `DEBT_COLLATERAL` is same as `DEBT_ONLY` but also returns total value and total LT-weighted value of
///           account's tokens, this mode is used during account liquidation
///         - `DEBT_COLLATERAL_SAFE_PRICES` is same as `DEBT_COLLATERAL` but uses safe prices from price oracle
enum CollateralCalcTask {
    GENERIC_PARAMS,
    DEBT_ONLY,
    FULL_COLLATERAL_CHECK_LAZY,
    DEBT_COLLATERAL,
    DEBT_COLLATERAL_SAFE_PRICES
}

struct CreditAccountInfo {
    uint256 debt;
    uint256 cumulativeIndexLastUpdate;
    uint128 cumulativeQuotaInterest;
    uint128 quotaFees;
    uint256 enabledTokensMask;
    uint16 flags;
    uint64 lastDebtUpdate;
    address borrower;
}

struct CollateralDebtData {
    uint256 debt;
    uint256 cumulativeIndexNow;
    uint256 cumulativeIndexLastUpdate;
    uint128 cumulativeQuotaInterest;
    uint256 accruedInterest;
    uint256 accruedFees;
    uint256 totalDebtUSD;
    uint256 totalValue;
    uint256 totalValueUSD;
    uint256 twvUSD;
    uint256 enabledTokensMask;
    uint256 quotedTokensMask;
    address[] quotedTokens;
    address _poolQuotaKeeper;
}

struct CollateralTokenData {
    address token;
    uint16 ltInitial;
    uint16 ltFinal;
    uint40 timestampRampStart;
    uint24 rampDuration;
}

struct RevocationPair {
    address spender;
    address token;
}

interface ICreditManagerV3Events {
    /// @notice Emitted when new credit configurator is set
    event SetCreditConfigurator(address indexed newConfigurator);
}

/// @title Credit manager V3 interface
interface ICreditManagerV3 is IVersion, ICreditManagerV3Events {
    function pool() external view returns (address);

    function underlying() external view returns (address);

    function creditFacade() external view returns (address);

    function creditConfigurator() external view returns (address);

    function addressProvider() external view returns (address);

    function accountFactory() external view returns (address);

    function name() external view returns (string memory);

    // ------------------ //
    // ACCOUNT MANAGEMENT //
    // ------------------ //

    function openCreditAccount(address onBehalfOf) external returns (address);

    function closeCreditAccount(address creditAccount) external;

    function liquidateCreditAccount(
        address creditAccount,
        CollateralDebtData calldata collateralDebtData,
        address to,
        bool isExpired
    ) external returns (uint256 remainingFunds, uint256 loss);

    function manageDebt(address creditAccount, uint256 amount, uint256 enabledTokensMask, ManageDebtAction action)
        external
        returns (uint256 newDebt, uint256 tokensToEnable, uint256 tokensToDisable);

    function addCollateral(address payer, address creditAccount, address token, uint256 amount)
        external
        returns (uint256 tokensToEnable);

    function withdrawCollateral(address creditAccount, address token, uint256 amount, address to)
        external
        returns (uint256 tokensToDisable);

    function externalCall(address creditAccount, address target, bytes calldata callData)
        external
        returns (bytes memory result);

    function approveToken(address creditAccount, address token, address spender, uint256 amount) external;

    function revokeAdapterAllowances(address creditAccount, RevocationPair[] calldata revocations) external;

    // -------- //
    // ADAPTERS //
    // -------- //

    function adapterToContract(address adapter) external view returns (address targetContract);

    function contractToAdapter(address targetContract) external view returns (address adapter);

    function execute(bytes calldata data) external returns (bytes memory result);

    function approveCreditAccount(address token, uint256 amount) external;

    function setActiveCreditAccount(address creditAccount) external;

    function getActiveCreditAccountOrRevert() external view returns (address creditAccount);

    // ----------------- //
    // COLLATERAL CHECKS //
    // ----------------- //

    function priceOracle() external view returns (address);

    function fullCollateralCheck(
        address creditAccount,
        uint256 enabledTokensMask,
        uint256[] calldata collateralHints,
        uint16 minHealthFactor,
        bool useSafePrices
    ) external returns (uint256 enabledTokensMaskAfter);

    function isLiquidatable(address creditAccount, uint16 minHealthFactor) external view returns (bool);

    function calcDebtAndCollateral(address creditAccount, CollateralCalcTask task)
        external
        view
        returns (CollateralDebtData memory cdd);

    // ------ //
    // QUOTAS //
    // ------ //

    function poolQuotaKeeper() external view returns (address);

    function quotedTokensMask() external view returns (uint256);

    function updateQuota(address creditAccount, address token, int96 quotaChange, uint96 minQuota, uint96 maxQuota)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    // --------------------- //
    // CREDIT MANAGER PARAMS //
    // --------------------- //

    function maxEnabledTokens() external view returns (uint8);

    function fees()
        external
        view
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount,
            uint16 feeLiquidationExpired,
            uint16 liquidationDiscountExpired
        );

    function collateralTokensCount() external view returns (uint8);

    function getTokenMaskOrRevert(address token) external view returns (uint256 tokenMask);

    function getTokenByMask(uint256 tokenMask) external view returns (address token);

    function liquidationThresholds(address token) external view returns (uint16 lt);

    function ltParams(address token)
        external
        view
        returns (uint16 ltInitial, uint16 ltFinal, uint40 timestampRampStart, uint24 rampDuration);

    function collateralTokenByMask(uint256 tokenMask)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    // ------------ //
    // ACCOUNT INFO //
    // ------------ //

    function creditAccountInfo(address creditAccount)
        external
        view
        returns (
            uint256 debt,
            uint256 cumulativeIndexLastUpdate,
            uint128 cumulativeQuotaInterest,
            uint128 quotaFees,
            uint256 enabledTokensMask,
            uint16 flags,
            uint64 lastDebtUpdate,
            address borrower
        );

    function getBorrowerOrRevert(address creditAccount) external view returns (address borrower);

    function flagsOf(address creditAccount) external view returns (uint16);

    function setFlagFor(address creditAccount, uint16 flag, bool value) external;

    function enabledTokensMaskOf(address creditAccount) external view returns (uint256);

    function creditAccounts() external view returns (address[] memory);

    function creditAccounts(uint256 offset, uint256 limit) external view returns (address[] memory);

    function creditAccountsLen() external view returns (uint256);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function addToken(address token) external;

    function setCollateralTokenData(
        address token,
        uint16 ltInitial,
        uint16 ltFinal,
        uint40 timestampRampStart,
        uint24 rampDuration
    ) external;

    function setFees(
        uint16 feeInterest,
        uint16 feeLiquidation,
        uint16 liquidationDiscount,
        uint16 feeLiquidationExpired,
        uint16 liquidationDiscountExpired
    ) external;

    function setQuotedMask(uint256 quotedTokensMask) external;

    function setMaxEnabledTokens(uint8 maxEnabledTokens) external;

    function setContractAllowance(address adapter, address targetContract) external;

    function setCreditFacade(address creditFacade) external;

    function setPriceOracle(address priceOracle) external;

    function setCreditConfigurator(address creditConfigurator) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IACL} from "@gearbox-protocol/core-v2/contracts/interfaces/IACL.sol";

import {AP_ACL, IAddressProviderV3, NO_VERSION_CONTROL} from "../interfaces/IAddressProviderV3.sol";
import {CallerNotConfiguratorException} from "../interfaces/IExceptions.sol";

import {SanityCheckTrait} from "./SanityCheckTrait.sol";

/// @title ACL trait
/// @notice Utility class for ACL (access-control list) consumers
abstract contract ACLTrait is SanityCheckTrait {
    /// @notice ACL contract address
    address public immutable acl;

    /// @notice Constructor
    /// @param addressProvider Address provider contract address
    constructor(address addressProvider) nonZeroAddress(addressProvider) {
        acl = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_ACL, NO_VERSION_CONTROL);
    }

    /// @dev Ensures that function caller has configurator role
    modifier configuratorOnly() {
        _ensureCallerIsConfigurator();
        _;
    }

    /// @dev Reverts if the caller is not the configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsConfigurator() internal view {
        if (!_isConfigurator({account: msg.sender})) {
            revert CallerNotConfiguratorException();
        }
    }

    /// @dev Checks whether given account has configurator role
    function _isConfigurator(address account) internal view returns (bool) {
        return IACL(acl).isConfigurator(account);
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title Version interface
/// @notice Defines contract version
interface IVersion {
    /// @notice Contract version
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IACLExceptions {
    /// @dev Thrown when attempting to delete an address from a set that is not a pausable admin
    error AddressNotPausableAdminException(address addr);

    /// @dev Thrown when attempting to delete an address from a set that is not a unpausable admin
    error AddressNotUnpausableAdminException(address addr);
}

interface IACLEvents {
    /// @dev Emits when a new admin is added that can pause contracts
    event PausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when a Pausable admin is removed
    event PausableAdminRemoved(address indexed admin);

    /// @dev Emits when a new admin is added that can unpause contracts
    event UnpausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when an Unpausable admin is removed
    event UnpausableAdminRemoved(address indexed admin);
}

/// @title ACL interface
interface IACL is IACLEvents, IACLExceptions, IVersion {
    /// @dev Returns true if the address is a pausable admin and false if not
    /// @param addr Address to check
    function isPausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if the address is unpausable admin and false if not
    /// @param addr Address to check
    function isUnpausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if an address has configurator rights
    /// @param account Address to check
    function isConfigurator(address account) external view returns (bool);

    /// @dev Returns address of configurator
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

uint256 constant NO_VERSION_CONTROL = 0;

bytes32 constant AP_CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
bytes32 constant AP_ACL = "ACL";
bytes32 constant AP_PRICE_ORACLE = "PRICE_ORACLE";
bytes32 constant AP_ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
bytes32 constant AP_DATA_COMPRESSOR = "DATA_COMPRESSOR";
bytes32 constant AP_TREASURY = "TREASURY";
bytes32 constant AP_GEAR_TOKEN = "GEAR_TOKEN";
bytes32 constant AP_WETH_TOKEN = "WETH_TOKEN";
bytes32 constant AP_WETH_GATEWAY = "WETH_GATEWAY";
bytes32 constant AP_ROUTER = "ROUTER";
bytes32 constant AP_BOT_LIST = "BOT_LIST";
bytes32 constant AP_GEAR_STAKING = "GEAR_STAKING";
bytes32 constant AP_ZAPPER_REGISTER = "ZAPPER_REGISTER";

interface IAddressProviderV3Events {
    /// @notice Emitted when an address is set for a contract key
    event SetAddress(bytes32 indexed key, address indexed value, uint256 indexed version);
}

/// @title Address provider V3 interface
interface IAddressProviderV3 is IAddressProviderV3Events, IVersion {
    function addresses(bytes32 key, uint256 _version) external view returns (address);

    function getAddressOrRevert(bytes32 key, uint256 _version) external view returns (address result);

    function setAddress(bytes32 key, address value, bool saveVersion) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {ZeroAddressException} from "../interfaces/IExceptions.sol";

/// @title Sanity check trait
abstract contract SanityCheckTrait {
    /// @dev Ensures that passed address is non-zero
    modifier nonZeroAddress(address addr) {
        _revertIfZeroAddress(addr);
        _;
    }

    /// @dev Reverts if address is zero
    function _revertIfZeroAddress(address addr) private pure {
        if (addr == address(0)) revert ZeroAddressException();
    }
}