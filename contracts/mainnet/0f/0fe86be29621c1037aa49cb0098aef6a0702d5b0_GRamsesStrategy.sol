// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "forge-std/src/Script.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/utils/ILpCallback.sol";
import "../interfaces/vaults/IERC20Vault.sol";
import "../interfaces/vaults/IRamsesV2Vault.sol";
import "../interfaces/vaults/IRamsesV2VaultGovernance.sol";
import "../interfaces/utils/ILpCallback.sol";

import "../interfaces/external/ramses/libraries/OracleLibrary.sol";
import "../libraries/external/FullMath.sol";
import "../libraries/ExceptionsLibrary.sol";

import "../utils/DefaultAccessControlLateInit.sol";

contract GRamsesStrategy is DefaultAccessControlLateInit, ILpCallback {
    using SafeERC20 for IERC20;

    struct ImmutableParams {
        uint24 fee;
        IRamsesV2Pool pool;
        IERC20Vault erc20Vault;
        IRamsesV2Vault lowerVault;
        IRamsesV2Vault upperVault;
        address router;
        address[] tokens;
    }

    struct MutableParams {
        uint32 timespan;
        int24 maxTickDeviation;
        int24 intervalWidth;
        int24 priceImpactD6;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 maxRatioDeviationX96;
        uint256 swapSlippageD;
        uint256 swappingAmountsCoefficientD;
        uint256[] minSwapAmounts;
    }

    struct State {
        int24 lowerTick;
        int24 upperTick;
        uint256 ratioX96;
    }

    uint256 public constant Q96 = 2**96;
    uint256 public constant D9 = 1e9;
    uint256 public constant D6 = 1e6;

    IRamsesV2NonfungiblePositionManager public immutable positionManager;

    struct Storage {
        ImmutableParams immutableParams;
        MutableParams mutableParams;
    }

    bytes32 public constant STORAGE_POSITION = keccak256("strategy.storage");

    function _contractStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    constructor(IRamsesV2NonfungiblePositionManager positionManager_) {
        positionManager = positionManager_;
    }

    function initialize(address admin, ImmutableParams memory immutableParams) external {
        DefaultAccessControlLateInit.init(admin);
        _contractStorage().immutableParams = immutableParams;
        for (uint256 i = 0; i < 2; i++) {
            IERC20(immutableParams.tokens[i]).safeIncreaseAllowance(address(positionManager), type(uint256).max);
            immutableParams.erc20Vault.externalCall(
                immutableParams.tokens[i],
                IERC20.approve.selector,
                abi.encode(immutableParams.router, type(uint256).max)
            );
        }
    }

    function getImmutableParams() public view returns (ImmutableParams memory) {
        return _contractStorage().immutableParams;
    }

    function getMutableParams() public view returns (MutableParams memory) {
        return _contractStorage().mutableParams;
    }

    function ensureNoMEV(Storage memory s) public view {
        (int24 averageTick, , bool withFail) = OracleLibrary.consult(
            address(s.immutableParams.pool),
            s.mutableParams.timespan
        );
        require(!withFail, ExceptionsLibrary.INVALID_STATE);
        (, int24 spotTick, , , , , ) = s.immutableParams.pool.slot0();
        int24 delta = spotTick - averageTick;
        if (delta < 0) delta = -delta;
        require(delta <= s.mutableParams.maxTickDeviation, ExceptionsLibrary.LIMIT_OVERFLOW);
    }

    function calculateExpectedState(Storage memory s) public view returns (State memory state) {
        (, int24 tick, , , , , ) = s.immutableParams.pool.slot0();
        int24 width = s.mutableParams.intervalWidth;
        state.lowerTick = tick - (tick % width);
        if (state.lowerTick > tick) {
            state.lowerTick -= width;
        }
        state.upperTick = state.lowerTick + width;
        int24 deltaX2 = 2 * tick - state.lowerTick - state.upperTick;
        if (deltaX2 < 0) {
            state.lowerTick -= width;
            state.upperTick -= width;
            state.ratioX96 = Q96 - FullMath.mulDiv(Q96, uint24(width * 2 + deltaX2), uint24(width * 2));
        } else {
            state.ratioX96 = FullMath.mulDiv(Q96, uint24(width * 2 - deltaX2), uint24(width * 2));
        }
    }

    function getCurrentState(Storage memory s) public view returns (State memory state) {
        uint256 lowerPositionId = s.immutableParams.lowerVault.positionId();
        if (lowerPositionId != 0) {
            uint128 lowerLiquidity;
            (, , , , , state.lowerTick, state.upperTick, lowerLiquidity, , , , ) = positionManager.positions(
                lowerPositionId
            );
            uint128 upperLiquidity;
            (, , , , , , , upperLiquidity, , , , ) = positionManager.positions(
                s.immutableParams.upperVault.positionId()
            );
            state.ratioX96 = FullMath.mulDiv(Q96, lowerLiquidity, lowerLiquidity + upperLiquidity);
        }
    }

    function calculateTargetRatioOfToken1(Storage memory s, uint256 ratioX96)
        public
        view
        returns (uint256 targetRatioOfToken1X96)
    {
        uint256[] memory lowerAmountsQ96 = s.immutableParams.lowerVault.liquidityToTokenAmounts(uint128(ratioX96));
        uint256[] memory upperAmountsQ96 = s.immutableParams.upperVault.liquidityToTokenAmounts(
            uint128(Q96 - ratioX96)
        );
        uint256 amount0 = lowerAmountsQ96[0] + upperAmountsQ96[0];
        uint256 amount1 = lowerAmountsQ96[1] + upperAmountsQ96[1];
        targetRatioOfToken1X96 = FullMath.mulDiv(Q96, amount1, amount0 + amount1);
    }

    function updateMutableParams(MutableParams memory newMutableParams) external {
        _requireAdmin();
        Storage storage s = _contractStorage();
        s.mutableParams = newMutableParams;
    }

    function updateRouter(address newRouter) external {
        _requireAdmin();
        Storage storage s = _contractStorage();
        ImmutableParams memory immutableParams = s.immutableParams;
        for (uint256 i = 0; i < immutableParams.tokens.length; i++) {
            immutableParams.erc20Vault.externalCall(
                immutableParams.tokens[i],
                IERC20.approve.selector,
                abi.encode(immutableParams.router, 0)
            );
            immutableParams.erc20Vault.externalCall(
                immutableParams.tokens[i],
                IERC20.approve.selector,
                abi.encode(newRouter, type(uint256).max)
            );
        }
        s.immutableParams.router = newRouter;
    }

    function updateVaultFarms(IRamsesV2VaultGovernance.StrategyParams memory newStrategyParams) external {
        _requireAdmin();
        ImmutableParams memory immutableParams = getImmutableParams();
        IRamsesV2VaultGovernance ramsesGovernance = IRamsesV2VaultGovernance(
            address(immutableParams.lowerVault.vaultGovernance())
        );
        ramsesGovernance.setStrategyParams(immutableParams.lowerVault.nft(), newStrategyParams);
        ramsesGovernance.setStrategyParams(immutableParams.upperVault.nft(), newStrategyParams);
    }

    function rebalance(
        bytes calldata swapData,
        uint256 minAmountOutInCaseOfSwap,
        uint256 deadline
    ) external {
        _requireAtLeastOperator();
        require(block.timestamp <= deadline, ExceptionsLibrary.TIMESTAMP);
        Storage memory s = _contractStorage();
        ensureNoMEV(s);

        State memory expected = calculateExpectedState(s);
        State memory current = getCurrentState(s);
        if (current.lowerTick == current.upperTick || expected.lowerTick != current.lowerTick) {
            _drainLiquidity(s);

            uint256 lowerVaultNft = _mint(s, expected.lowerTick, expected.upperTick);
            uint256 upperVaultNft = _mint(
                s,
                expected.lowerTick + s.mutableParams.intervalWidth,
                expected.upperTick + s.mutableParams.intervalWidth
            );

            uint256 oldLowerVaultNft = s.immutableParams.lowerVault.positionId();
            uint256 oldUpperVaultNft = s.immutableParams.upperVault.positionId();

            if (oldLowerVaultNft != 0) {
                s.immutableParams.lowerVault.collectRewards();
                s.immutableParams.upperVault.collectRewards();
            }

            positionManager.safeTransferFrom(address(this), address(s.immutableParams.lowerVault), lowerVaultNft);
            positionManager.safeTransferFrom(address(this), address(s.immutableParams.upperVault), upperVaultNft);

            if (oldLowerVaultNft != 0) {
                positionManager.burn(oldLowerVaultNft);
                emit PositionBurned(oldLowerVaultNft);
                positionManager.burn(oldUpperVaultNft);
                emit PositionBurned(oldUpperVaultNft);
            }
        } else {
            if (expected.ratioX96 + s.mutableParams.maxRatioDeviationX96 < current.ratioX96) {
                _drainLiquidity(s);
            } else if (current.ratioX96 + s.mutableParams.maxRatioDeviationX96 < expected.ratioX96) {
                _drainLiquidity(s);
            }
        }

        _swapToTarget(s, expected, swapData, minAmountOutInCaseOfSwap);
        _pushIntoRamses(s, expected.ratioX96);

        emit Rebalance(tx.origin, msg.sender);
    }

    function calculateAmountsForSwap(
        uint256[] memory currentAmounts,
        int24 priceImpactD6,
        uint256 priceX96,
        uint256 targetRatioOfToken1X96
    ) public pure returns (uint256 tokenInIndex, uint256 amountIn) {
        uint256 targetRatioOfToken0X96 = Q96 - targetRatioOfToken1X96;
        uint256 currentRatioOfToken1X96 = FullMath.mulDiv(
            currentAmounts[1],
            Q96,
            currentAmounts[1] + FullMath.mulDiv(currentAmounts[0], priceX96, Q96)
        );

        uint256 feesX96 = FullMath.mulDiv(Q96, uint256(int256(priceImpactD6)), D6);

        if (currentRatioOfToken1X96 > targetRatioOfToken1X96) {
            tokenInIndex = 1;
            // (dx * y0 - dy * x0 * p) / (1 - dy * fee)
            uint256 invertedPriceX96 = FullMath.mulDiv(Q96, Q96, priceX96);
            amountIn = FullMath.mulDiv(
                FullMath.mulDiv(currentAmounts[1], targetRatioOfToken0X96, Q96) -
                    FullMath.mulDiv(targetRatioOfToken1X96, currentAmounts[0], invertedPriceX96),
                Q96,
                Q96 - FullMath.mulDiv(targetRatioOfToken1X96, feesX96, Q96)
            );
        } else {
            // (dy * x0 - dx * y0 / p) / (1 - dx * fee)
            tokenInIndex = 0;
            amountIn = FullMath.mulDiv(
                FullMath.mulDiv(currentAmounts[0], targetRatioOfToken1X96, Q96) -
                    FullMath.mulDiv(targetRatioOfToken0X96, currentAmounts[1], priceX96),
                Q96,
                Q96 - FullMath.mulDiv(targetRatioOfToken0X96, feesX96, Q96)
            );
        }
        if (amountIn > currentAmounts[tokenInIndex]) {
            amountIn = currentAmounts[tokenInIndex];
        }
    }

    function _pushIntoRamses(Storage memory s, uint256 ratioX96) private {
        (uint256[] memory tvl, ) = s.immutableParams.erc20Vault.tvl();
        uint256[] memory lowerAmountsQ96 = s.immutableParams.lowerVault.liquidityToTokenAmounts(uint128(ratioX96));
        uint256[] memory upperAmountsQ96 = s.immutableParams.upperVault.liquidityToTokenAmounts(
            uint128(Q96 - ratioX96)
        );

        uint256 amount0 = lowerAmountsQ96[0] + upperAmountsQ96[0];
        uint256 amount1 = lowerAmountsQ96[1] + upperAmountsQ96[1];

        uint256 coefficientX96;
        if (amount0 > amount1) {
            coefficientX96 = FullMath.mulDiv(Q96, tvl[0], amount0);
        } else {
            coefficientX96 = FullMath.mulDiv(Q96, tvl[1], amount1);
        }
        uint256[] memory tokenAmounts = new uint256[](2);
        for (uint256 i = 0; i < 2; i++) {
            tokenAmounts[i] = FullMath.mulDiv(coefficientX96, lowerAmountsQ96[i], Q96);
        }
        if (tokenAmounts[0] > 0 || tokenAmounts[1] > 0) {
            s.immutableParams.erc20Vault.pull(
                address(s.immutableParams.lowerVault),
                s.immutableParams.tokens,
                tokenAmounts,
                ""
            );
        }
        (tokenAmounts, ) = s.immutableParams.erc20Vault.tvl();
        if (tokenAmounts[0] > 0 || tokenAmounts[1] > 0) {
            s.immutableParams.erc20Vault.pull(
                address(s.immutableParams.upperVault),
                s.immutableParams.tokens,
                tokenAmounts,
                ""
            );
        }
    }

    function _mint(
        Storage memory s,
        int24 lowerTick,
        int24 upperTick
    ) private returns (uint256 nft) {
        (nft, , , ) = positionManager.mint(
            IRamsesV2NonfungiblePositionManager.MintParams({
                token0: s.immutableParams.tokens[0],
                token1: s.immutableParams.tokens[1],
                fee: s.immutableParams.fee,
                tickLower: lowerTick,
                tickUpper: upperTick,
                amount0Desired: s.mutableParams.amount0Desired,
                amount1Desired: s.mutableParams.amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: type(uint256).max
            })
        );
        emit PositionMinted(nft);
    }

    function _drainLiquidity(Storage memory s) private {
        // drain liquidity from vaults
        if (s.immutableParams.lowerVault.positionId() != 0) {
            s.immutableParams.lowerVault.pull(
                address(s.immutableParams.erc20Vault),
                s.immutableParams.lowerVault.vaultTokens(),
                s.immutableParams.lowerVault.liquidityToTokenAmounts(type(uint128).max),
                ""
            );
            s.immutableParams.upperVault.pull(
                address(s.immutableParams.erc20Vault),
                s.immutableParams.upperVault.vaultTokens(),
                s.immutableParams.upperVault.liquidityToTokenAmounts(type(uint128).max),
                ""
            );
        }
    }

    function _swapToTarget(
        Storage memory s,
        State memory state,
        bytes calldata swapData,
        uint256 minAmountOutInCaseOfSwap
    ) private {
        uint256 priceX96;
        uint256 tokenInIndex;
        uint256 amountIn;
        {
            (uint160 sqrtSpotPriceX96, , , , , , ) = s.immutableParams.pool.slot0();
            priceX96 = FullMath.mulDiv(sqrtSpotPriceX96, sqrtSpotPriceX96, Q96);
            (uint256[] memory currentAmounts, ) = s.immutableParams.erc20Vault.tvl();
            (tokenInIndex, amountIn) = calculateAmountsForSwap(
                currentAmounts,
                s.mutableParams.priceImpactD6,
                priceX96,
                calculateTargetRatioOfToken1(s, state.ratioX96)
            );
        }

        if (amountIn < s.mutableParams.minSwapAmounts[tokenInIndex]) {
            return;
        }

        if (tokenInIndex == 1) {
            priceX96 = FullMath.mulDiv(Q96, Q96, priceX96);
        }

        (uint256[] memory tvlBefore, ) = s.immutableParams.erc20Vault.tvl();

        s.immutableParams.erc20Vault.externalCall(s.immutableParams.router, bytes4(swapData[:4]), swapData[4:]);

        uint256 actualAmountIn;
        uint256 actualAmountOut;

        {
            (uint256[] memory tvlAfter, ) = s.immutableParams.erc20Vault.tvl();

            require(tvlAfter[tokenInIndex] <= tvlBefore[tokenInIndex], ExceptionsLibrary.INVARIANT);
            require(tvlAfter[tokenInIndex ^ 1] >= tvlBefore[tokenInIndex ^ 1], ExceptionsLibrary.INVARIANT);

            actualAmountIn = tvlBefore[tokenInIndex] - tvlAfter[tokenInIndex];
            actualAmountOut = tvlAfter[tokenInIndex ^ 1] - tvlBefore[tokenInIndex ^ 1];
        }

        uint256 actualSwapPriceX96 = FullMath.mulDiv(actualAmountOut, Q96, actualAmountIn);

        require(actualAmountOut >= minAmountOutInCaseOfSwap, ExceptionsLibrary.LIMIT_UNDERFLOW);

        require(
            FullMath.mulDiv(priceX96, D9 - s.mutableParams.swapSlippageD, D9) <= actualSwapPriceX96,
            ExceptionsLibrary.LIMIT_UNDERFLOW
        );

        require(
            FullMath.mulDiv(amountIn, D9 - s.mutableParams.swappingAmountsCoefficientD, D9) <= actualAmountIn,
            ExceptionsLibrary.LIMIT_UNDERFLOW
        );

        require(
            FullMath.mulDiv(actualAmountIn, D9 - s.mutableParams.swappingAmountsCoefficientD, D9) <= amountIn,
            ExceptionsLibrary.LIMIT_UNDERFLOW
        );

        emit TokensSwapped(actualAmountIn, actualAmountOut, tokenInIndex);
    }

    /// @inheritdoc ILpCallback
    function depositCallback() external {
        Storage memory s = _contractStorage();
        State memory current = getCurrentState(s);
        _pushIntoRamses(s, current.ratioX96);
    }

    /// @inheritdoc ILpCallback
    function withdrawCallback() external {}

    /// @notice Emitted after a successful token swap
    /// @param amountIn amount of token, that pushed into SwapRouter
    /// @param amountOut amount of token, that recieved from SwapRouter
    /// @param tokenInIndex index of token, that pushed into SwapRouter
    event TokensSwapped(uint256 amountIn, uint256 amountOut, uint256 tokenInIndex);

    /// @notice Emited when mutable parameters are successfully updated
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param mutableParams Updated parameters
    event UpdateMutableParams(address indexed origin, address indexed sender, MutableParams mutableParams);

    /// @notice Emited when the rebalance is successfully completed
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    event Rebalance(address indexed origin, address indexed sender);

    /// @notice Emited when a new ramses v2 position is created
    /// @param tokenId nft of new ramses v2 position
    event PositionMinted(uint256 tokenId);

    /// @notice Emited when a ramses v2 position is burned
    /// @param tokenId nft of ramses v2 position
    event PositionBurned(uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

// 💬 ABOUT
// Forge Std's default Script.

// 🧩 MODULES
import {console} from "./console.sol";
import {console2} from "./console2.sol";
import {safeconsole} from "./safeconsole.sol";
import {StdChains} from "./StdChains.sol";
import {StdCheatsSafe} from "./StdCheats.sol";
import {stdJson} from "./StdJson.sol";
import {stdMath} from "./StdMath.sol";
import {StdStorage, stdStorageSafe} from "./StdStorage.sol";
import {StdStyle} from "./StdStyle.sol";
import {StdUtils} from "./StdUtils.sol";
import {VmSafe} from "./Vm.sol";

// 📦 BOILERPLATE
import {ScriptBase} from "./Base.sol";

// ⭐️ SCRIPT
abstract contract Script is StdChains, StdCheatsSafe, StdUtils, ScriptBase {
    // Note: IS_SCRIPT() must return true.
    bool public IS_SCRIPT = true;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILpCallback {
    /// @notice Function, that ERC20RootVault calling after deposit
    function depositCallback() external;

    /// @notice Function, that ERC20RootVault calling after withdraw
    function withdrawCallback() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IIntegrationVault.sol";

interface IERC20Vault is IIntegrationVault {
    /// @notice Initialized a new contract.
    /// @dev Can only be initialized by vault governance
    /// @param nft_ NFT of the vault in the VaultRegistry
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    function initialize(uint256 nft_, address[] memory vaultTokens_) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IIntegrationVault.sol";
import "../external/ramses/IRamsesV2NonfungiblePositionManager.sol";
import "../external/ramses/IRamsesV2Pool.sol";

interface IRamsesV2Vault is IERC721Receiver, IIntegrationVault {
    struct Options {
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function positionManager() external view returns (IRamsesV2NonfungiblePositionManager);

    function pool() external view returns (IRamsesV2Pool);

    function erc20Vault() external view returns (address);

    function positionId() external view returns (uint256);

    function liquidityToTokenAmounts(uint128 liquidity) external view returns (uint256[] memory tokenAmounts);

    function tokenAmountsToLiquidity(uint256[] memory tokenAmounts) external view returns (uint128 liquidity);

    function initialize(
        uint256 nft_,
        address[] memory vaultTokens_,
        uint24 fee_,
        address helper_,
        address erc20Vault_
    ) external;

    function collectEarnings() external returns (uint256[] memory collectedEarnings);

    function collectRewards() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../external/ramses/IRamsesV2NonfungiblePositionManager.sol";
import "../oracles/IOracle.sol";
import "./IVaultGovernance.sol";
import "./IRamsesV2Vault.sol";

interface IRamsesV2VaultGovernance is IVaultGovernance {
    /// @notice Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @param positionManager Reference to Ramses IRamsesNonfungiblePositionManager
    struct DelayedProtocolParams {
        IRamsesV2NonfungiblePositionManager positionManager;
        IOracle oracle;
    }

    /// @param safetyIndicesSet Safety indices for oracle
    struct DelayedStrategyParams {
        uint32 safetyIndicesSet;
    }

    struct StrategyParams {
        address farm;
        address gaugeV2;
        address[] rewards;
        bool instantExitFlag;
    }

    /// @notice Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function delayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Delayed Protocol Params staged for commit after delay.
    function stagedDelayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Stage Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @param params New params
    function stageDelayedProtocolParams(DelayedProtocolParams calldata params) external;

    /// @notice Commit Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function commitDelayedProtocolParams() external;

    /// @notice Delayed Strategy Params
    /// @param nft VaultRegistry NFT of the vault
    function delayedStrategyParams(uint256 nft) external view returns (DelayedStrategyParams memory);

    /// @notice Delayed Strategy Params staged for commit after delay.
    /// @param nft VaultRegistry NFT of the vault
    function stagedDelayedStrategyParams(uint256 nft) external view returns (DelayedStrategyParams memory);

    /// @notice Stage Delayed Strategy Params, i.e. Params that could be changed by Strategy or Protocol Governance with Protocol Governance delay.
    /// @param nft VaultRegistry NFT of the vault
    /// @param params New params
    function stageDelayedStrategyParams(uint256 nft, DelayedStrategyParams calldata params) external;

    /// @notice Commit Delayed Strategy Params, i.e. Params that could be changed by Strategy or Protocol Governance with Protocol Governance delay.
    /// @dev Can only be called after delayedStrategyParamsTimestamp
    /// @param nft VaultRegistry NFT of the vault
    function commitDelayedStrategyParams(uint256 nft) external;

    /// @notice Delayed Strategy Params
    /// @param nft VaultRegistry NFT of the vault
    function strategyParams(uint256 nft) external view returns (StrategyParams memory);

    /// @notice Delayed Strategy Params staged for commit after delay.
    /// @param nft VaultRegistry NFT of the vault
    function setStrategyParams(uint256 nft, StrategyParams calldata params) external;

    /// @notice Deploys a new vault.
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    /// @param owner_ Owner of the vault NFT
    /// @param fee_ Fee of the RamsesV2 pool
    /// @param helper_ address of helper for RamsesV2 arithmetic with ticks
    function createVault(
        address[] memory vaultTokens_,
        address owner_,
        uint24 fee_,
        address helper_,
        address erc20Vault_
    ) external returns (IRamsesV2Vault vault, uint256 nft);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../IRamsesV2Pool.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    /// @return withFail Flag that true if function observe of IRamsesV2Pool reverts with some error
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (
            int24 arithmeticMeanTick,
            uint128 harmonicMeanLiquidity,
            bool withFail
        )
    {
        require(secondsAgo != 0, "BP");

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        try IRamsesV2Pool(pool).observe(secondsAgos) returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s,
            uint160[] memory
        ) {
            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[1] -
                secondsPerLiquidityCumulativeX128s[0];

            arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));
            // Always round to negative infinity
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0))
                arithmeticMeanTick--;

            // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
            uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
            harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
        } catch {
            return (0, 0, true);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // diff: original uint256 twos = -denominator & denominator;
            uint256 twos = uint256(-int256(denominator)) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }

    function mulDivFloor(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0, "0 denom");
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1, "denom <= prod1");

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        unchecked {
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivCeiling(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDivFloor(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Exceptions stores project`s smart-contracts exceptions
library ExceptionsLibrary {
    string constant ADDRESS_ZERO = "AZ";
    string constant VALUE_ZERO = "VZ";
    string constant EMPTY_LIST = "EMPL";
    string constant NOT_FOUND = "NF";
    string constant INIT = "INIT";
    string constant DUPLICATE = "DUP";
    string constant NULL = "NULL";
    string constant TIMESTAMP = "TS";
    string constant FORBIDDEN = "FRB";
    string constant ALLOWLIST = "ALL";
    string constant LIMIT_OVERFLOW = "LIMO";
    string constant LIMIT_UNDERFLOW = "LIMU";
    string constant INVALID_VALUE = "INV";
    string constant INVARIANT = "INVA";
    string constant INVALID_TARGET = "INVTR";
    string constant INVALID_TOKEN = "INVTO";
    string constant INVALID_INTERFACE = "INVI";
    string constant INVALID_SELECTOR = "INVS";
    string constant INVALID_STATE = "INVST";
    string constant INVALID_LENGTH = "INVL";
    string constant LOCK = "LCKD";
    string constant DISABLED = "DIS";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../interfaces/utils/IDefaultAccessControl.sol";
import "../libraries/ExceptionsLibrary.sol";

/// @notice This is a default access control with 3 roles:
///
/// - ADMIN: allowed to do anything
/// - ADMIN_DELEGATE: allowed to do anything except assigning ADMIN and ADMIN_DELEGATE roles
/// - OPERATOR: low-privileged role, generally keeper or some other bot
contract DefaultAccessControlLateInit is IDefaultAccessControl, AccessControlEnumerable {
    bool public initialized;

    bytes32 public constant OPERATOR = keccak256("operator");
    bytes32 public constant ADMIN_ROLE = keccak256("admin");
    bytes32 public constant ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");

    // -------------------------  EXTERNAL, VIEW  ------------------------------

    /// @inheritdoc IDefaultAccessControl
    function isAdmin(address sender) public view returns (bool) {
        return hasRole(ADMIN_ROLE, sender) || hasRole(ADMIN_DELEGATE_ROLE, sender);
    }

    /// @inheritdoc IDefaultAccessControl
    function isOperator(address sender) public view returns (bool) {
        return hasRole(OPERATOR, sender);
    }

    // -------------------------  EXTERNAL, MUTATING  ------------------------------

    /// @notice Initializes a new contract with roles and single ADMIN.
    /// @param admin Admin of the contract
    function init(address admin) public {
        require(admin != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(!initialized, ExceptionsLibrary.INIT);

        _setupRole(OPERATOR, admin);
        _setupRole(ADMIN_ROLE, admin);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_DELEGATE_ROLE, ADMIN_ROLE);
        _setRoleAdmin(OPERATOR, ADMIN_DELEGATE_ROLE);

        initialized = true;
    }

    // -------------------------  INTERNAL, VIEW  ------------------------------

    function _requireAdmin() internal view {
        require(isAdmin(msg.sender), ExceptionsLibrary.FORBIDDEN);
    }

    function _requireAtLeastOperator() internal view {
        require(isAdmin(msg.sender) || isOperator(msg.sender), ExceptionsLibrary.FORBIDDEN);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @dev The original console.sol uses `int` and `uint` for computing function selectors, but it should
/// use `int256` and `uint256`. This modified version fixes that. This version is recommended
/// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
/// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
/// Reference: https://github.com/NomicFoundation/hardhat/issues/2178
library console2 {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _castLogPayloadViewToPure(
        function(bytes memory) internal view fnIn
    ) internal pure returns (function(bytes memory) internal pure fnOut) {
        assembly {
            fnOut := fnIn
        }
    }

    function _sendLogPayload(bytes memory payload) internal pure {
        _castLogPayloadViewToPure(_sendLogPayloadView)(payload);
    }

    function _sendLogPayloadView(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal pure {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(int256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function log(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, int256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,int256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

/// @author philogy <https://github.com/philogy>
/// @dev Code generated automatically by script.
library safeconsole {
    uint256 constant CONSOLE_ADDR = 0x000000000000000000000000000000000000000000636F6e736F6c652e6c6f67;

    // Credit to [0age](https://twitter.com/z0age/status/1654922202930888704) and [0xdapper](https://github.com/foundry-rs/forge-std/pull/374)
    // for the view-to-pure log trick.
    function _sendLogPayload(uint256 offset, uint256 size) private pure {
        function(uint256, uint256) internal view fnIn = _sendLogPayloadView;
        function(uint256, uint256) internal pure pureSendLogPayload;
        assembly {
            pureSendLogPayload := fnIn
        }
        pureSendLogPayload(offset, size);
    }

    function _sendLogPayloadView(uint256 offset, uint256 size) private view {
        assembly {
            pop(staticcall(gas(), CONSOLE_ADDR, offset, size, 0x0, 0x0))
        }
    }

    function _memcopy(uint256 fromOffset, uint256 toOffset, uint256 length) private pure {
        function(uint256, uint256, uint256) internal view fnIn = _memcopyView;
        function(uint256, uint256, uint256) internal pure pureMemcopy;
        assembly {
            pureMemcopy := fnIn
        }
        pureMemcopy(fromOffset, toOffset, length);
    }

    function _memcopyView(uint256 fromOffset, uint256 toOffset, uint256 length) private view {
        assembly {
            pop(staticcall(gas(), 0x4, fromOffset, length, toOffset, length))
        }
    }

    function logMemory(uint256 offset, uint256 length) internal pure {
        if (offset >= 0x60) {
            // Sufficient memory before slice to prepare call header.
            bytes32 m0;
            bytes32 m1;
            bytes32 m2;
            assembly {
                m0 := mload(sub(offset, 0x60))
                m1 := mload(sub(offset, 0x40))
                m2 := mload(sub(offset, 0x20))
                // Selector of `logBytes(bytes)`.
                mstore(sub(offset, 0x60), 0xe17bf956)
                mstore(sub(offset, 0x40), 0x20)
                mstore(sub(offset, 0x20), length)
            }
            _sendLogPayload(offset - 0x44, length + 0x44);
            assembly {
                mstore(sub(offset, 0x60), m0)
                mstore(sub(offset, 0x40), m1)
                mstore(sub(offset, 0x20), m2)
            }
        } else {
            // Insufficient space, so copy slice forward, add header and reverse.
            bytes32 m0;
            bytes32 m1;
            bytes32 m2;
            uint256 endOffset = offset + length;
            assembly {
                m0 := mload(add(endOffset, 0x00))
                m1 := mload(add(endOffset, 0x20))
                m2 := mload(add(endOffset, 0x40))
            }
            _memcopy(offset, offset + 0x60, length);
            assembly {
                // Selector of `logBytes(bytes)`.
                mstore(add(offset, 0x00), 0xe17bf956)
                mstore(add(offset, 0x20), 0x20)
                mstore(add(offset, 0x40), length)
            }
            _sendLogPayload(offset + 0x1c, length + 0x44);
            _memcopy(offset + 0x60, offset, length);
            assembly {
                mstore(add(endOffset, 0x00), m0)
                mstore(add(endOffset, 0x20), m1)
                mstore(add(endOffset, 0x40), m2)
            }
        }
    }

    function log(address p0) internal pure {
        bytes32 m0;
        bytes32 m1;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            // Selector of `log(address)`.
            mstore(0x00, 0x2c2ecbc2)
            mstore(0x20, p0)
        }
        _sendLogPayload(0x1c, 0x24);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
        }
    }

    function log(bool p0) internal pure {
        bytes32 m0;
        bytes32 m1;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            // Selector of `log(bool)`.
            mstore(0x00, 0x32458eed)
            mstore(0x20, p0)
        }
        _sendLogPayload(0x1c, 0x24);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
        }
    }

    function log(uint256 p0) internal pure {
        bytes32 m0;
        bytes32 m1;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            // Selector of `log(uint256)`.
            mstore(0x00, 0xf82c50f1)
            mstore(0x20, p0)
        }
        _sendLogPayload(0x1c, 0x24);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
        }
    }

    function log(bytes32 p0) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(string)`.
            mstore(0x00, 0x41304fac)
            mstore(0x20, 0x20)
            writeString(0x40, p0)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(address p0, address p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            // Selector of `log(address,address)`.
            mstore(0x00, 0xdaf0d4aa)
            mstore(0x20, p0)
            mstore(0x40, p1)
        }
        _sendLogPayload(0x1c, 0x44);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
        }
    }

    function log(address p0, bool p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            // Selector of `log(address,bool)`.
            mstore(0x00, 0x75b605d3)
            mstore(0x20, p0)
            mstore(0x40, p1)
        }
        _sendLogPayload(0x1c, 0x44);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
        }
    }

    function log(address p0, uint256 p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            // Selector of `log(address,uint256)`.
            mstore(0x00, 0x8309e8a8)
            mstore(0x20, p0)
            mstore(0x40, p1)
        }
        _sendLogPayload(0x1c, 0x44);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
        }
    }

    function log(address p0, bytes32 p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,string)`.
            mstore(0x00, 0x759f86bb)
            mstore(0x20, p0)
            mstore(0x40, 0x40)
            writeString(0x60, p1)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, address p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            // Selector of `log(bool,address)`.
            mstore(0x00, 0x853c4849)
            mstore(0x20, p0)
            mstore(0x40, p1)
        }
        _sendLogPayload(0x1c, 0x44);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
        }
    }

    function log(bool p0, bool p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            // Selector of `log(bool,bool)`.
            mstore(0x00, 0x2a110e83)
            mstore(0x20, p0)
            mstore(0x40, p1)
        }
        _sendLogPayload(0x1c, 0x44);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
        }
    }

    function log(bool p0, uint256 p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            // Selector of `log(bool,uint256)`.
            mstore(0x00, 0x399174d3)
            mstore(0x20, p0)
            mstore(0x40, p1)
        }
        _sendLogPayload(0x1c, 0x44);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
        }
    }

    function log(bool p0, bytes32 p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,string)`.
            mstore(0x00, 0x8feac525)
            mstore(0x20, p0)
            mstore(0x40, 0x40)
            writeString(0x60, p1)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, address p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            // Selector of `log(uint256,address)`.
            mstore(0x00, 0x69276c86)
            mstore(0x20, p0)
            mstore(0x40, p1)
        }
        _sendLogPayload(0x1c, 0x44);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
        }
    }

    function log(uint256 p0, bool p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            // Selector of `log(uint256,bool)`.
            mstore(0x00, 0x1c9d7eb3)
            mstore(0x20, p0)
            mstore(0x40, p1)
        }
        _sendLogPayload(0x1c, 0x44);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
        }
    }

    function log(uint256 p0, uint256 p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            // Selector of `log(uint256,uint256)`.
            mstore(0x00, 0xf666715a)
            mstore(0x20, p0)
            mstore(0x40, p1)
        }
        _sendLogPayload(0x1c, 0x44);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
        }
    }

    function log(uint256 p0, bytes32 p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,string)`.
            mstore(0x00, 0x643fd0df)
            mstore(0x20, p0)
            mstore(0x40, 0x40)
            writeString(0x60, p1)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bytes32 p0, address p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(string,address)`.
            mstore(0x00, 0x319af333)
            mstore(0x20, 0x40)
            mstore(0x40, p1)
            writeString(0x60, p0)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bytes32 p0, bool p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(string,bool)`.
            mstore(0x00, 0xc3b55635)
            mstore(0x20, 0x40)
            mstore(0x40, p1)
            writeString(0x60, p0)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bytes32 p0, uint256 p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(string,uint256)`.
            mstore(0x00, 0xb60e72cc)
            mstore(0x20, 0x40)
            mstore(0x40, p1)
            writeString(0x60, p0)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bytes32 p0, bytes32 p1) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,string)`.
            mstore(0x00, 0x4b5c4277)
            mstore(0x20, 0x40)
            mstore(0x40, 0x80)
            writeString(0x60, p0)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, address p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(address,address,address)`.
            mstore(0x00, 0x018c84c2)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(address p0, address p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(address,address,bool)`.
            mstore(0x00, 0xf2a66286)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(address p0, address p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(address,address,uint256)`.
            mstore(0x00, 0x17fe6185)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(address p0, address p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(address,address,string)`.
            mstore(0x00, 0x007150be)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x60)
            writeString(0x80, p2)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(address p0, bool p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(address,bool,address)`.
            mstore(0x00, 0xf11699ed)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(address p0, bool p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(address,bool,bool)`.
            mstore(0x00, 0xeb830c92)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(address p0, bool p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(address,bool,uint256)`.
            mstore(0x00, 0x9c4f99fb)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(address p0, bool p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(address,bool,string)`.
            mstore(0x00, 0x212255cc)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x60)
            writeString(0x80, p2)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(address p0, uint256 p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(address,uint256,address)`.
            mstore(0x00, 0x7bc0d848)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(address p0, uint256 p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(address,uint256,bool)`.
            mstore(0x00, 0x678209a8)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(address p0, uint256 p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(address,uint256,uint256)`.
            mstore(0x00, 0xb69bcaf6)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(address p0, uint256 p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(address,uint256,string)`.
            mstore(0x00, 0xa1f2e8aa)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x60)
            writeString(0x80, p2)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(address p0, bytes32 p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(address,string,address)`.
            mstore(0x00, 0xf08744e8)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, p2)
            writeString(0x80, p1)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(address p0, bytes32 p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(address,string,bool)`.
            mstore(0x00, 0xcf020fb1)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, p2)
            writeString(0x80, p1)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(address p0, bytes32 p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(address,string,uint256)`.
            mstore(0x00, 0x67dd6ff1)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, p2)
            writeString(0x80, p1)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(address p0, bytes32 p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            // Selector of `log(address,string,string)`.
            mstore(0x00, 0xfb772265)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, 0xa0)
            writeString(0x80, p1)
            writeString(0xc0, p2)
        }
        _sendLogPayload(0x1c, 0xe4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
        }
    }

    function log(bool p0, address p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(bool,address,address)`.
            mstore(0x00, 0xd2763667)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(bool p0, address p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(bool,address,bool)`.
            mstore(0x00, 0x18c9c746)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(bool p0, address p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(bool,address,uint256)`.
            mstore(0x00, 0x5f7b9afb)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(bool p0, address p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(bool,address,string)`.
            mstore(0x00, 0xde9a9270)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x60)
            writeString(0x80, p2)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bool p0, bool p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(bool,bool,address)`.
            mstore(0x00, 0x1078f68d)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(bool p0, bool p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(bool,bool,bool)`.
            mstore(0x00, 0x50709698)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(bool p0, bool p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(bool,bool,uint256)`.
            mstore(0x00, 0x12f21602)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(bool p0, bool p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(bool,bool,string)`.
            mstore(0x00, 0x2555fa46)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x60)
            writeString(0x80, p2)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bool p0, uint256 p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(bool,uint256,address)`.
            mstore(0x00, 0x088ef9d2)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(bool p0, uint256 p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(bool,uint256,bool)`.
            mstore(0x00, 0xe8defba9)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(bool p0, uint256 p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(bool,uint256,uint256)`.
            mstore(0x00, 0x37103367)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(bool p0, uint256 p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(bool,uint256,string)`.
            mstore(0x00, 0xc3fc3970)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x60)
            writeString(0x80, p2)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bool p0, bytes32 p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(bool,string,address)`.
            mstore(0x00, 0x9591b953)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, p2)
            writeString(0x80, p1)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bool p0, bytes32 p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(bool,string,bool)`.
            mstore(0x00, 0xdbb4c247)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, p2)
            writeString(0x80, p1)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bool p0, bytes32 p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(bool,string,uint256)`.
            mstore(0x00, 0x1093ee11)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, p2)
            writeString(0x80, p1)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bool p0, bytes32 p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            // Selector of `log(bool,string,string)`.
            mstore(0x00, 0xb076847f)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, 0xa0)
            writeString(0x80, p1)
            writeString(0xc0, p2)
        }
        _sendLogPayload(0x1c, 0xe4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
        }
    }

    function log(uint256 p0, address p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(uint256,address,address)`.
            mstore(0x00, 0xbcfd9be0)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(uint256 p0, address p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(uint256,address,bool)`.
            mstore(0x00, 0x9b6ec042)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(uint256 p0, address p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(uint256,address,uint256)`.
            mstore(0x00, 0x5a9b5ed5)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(uint256 p0, address p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(uint256,address,string)`.
            mstore(0x00, 0x63cb41f9)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x60)
            writeString(0x80, p2)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(uint256 p0, bool p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(uint256,bool,address)`.
            mstore(0x00, 0x35085f7b)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(uint256 p0, bool p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(uint256,bool,bool)`.
            mstore(0x00, 0x20718650)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(uint256 p0, bool p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(uint256,bool,uint256)`.
            mstore(0x00, 0x20098014)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(uint256 p0, bool p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(uint256,bool,string)`.
            mstore(0x00, 0x85775021)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x60)
            writeString(0x80, p2)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(uint256 p0, uint256 p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(uint256,uint256,address)`.
            mstore(0x00, 0x5c96b331)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(uint256 p0, uint256 p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(uint256,uint256,bool)`.
            mstore(0x00, 0x4766da72)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            // Selector of `log(uint256,uint256,uint256)`.
            mstore(0x00, 0xd1ed7a3c)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
        }
        _sendLogPayload(0x1c, 0x64);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
        }
    }

    function log(uint256 p0, uint256 p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(uint256,uint256,string)`.
            mstore(0x00, 0x71d04af2)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x60)
            writeString(0x80, p2)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(uint256 p0, bytes32 p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(uint256,string,address)`.
            mstore(0x00, 0x7afac959)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, p2)
            writeString(0x80, p1)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(uint256 p0, bytes32 p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(uint256,string,bool)`.
            mstore(0x00, 0x4ceda75a)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, p2)
            writeString(0x80, p1)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(uint256 p0, bytes32 p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(uint256,string,uint256)`.
            mstore(0x00, 0x37aa7d4c)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, p2)
            writeString(0x80, p1)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(uint256 p0, bytes32 p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            // Selector of `log(uint256,string,string)`.
            mstore(0x00, 0xb115611f)
            mstore(0x20, p0)
            mstore(0x40, 0x60)
            mstore(0x60, 0xa0)
            writeString(0x80, p1)
            writeString(0xc0, p2)
        }
        _sendLogPayload(0x1c, 0xe4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
        }
    }

    function log(bytes32 p0, address p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(string,address,address)`.
            mstore(0x00, 0xfcec75e0)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, p2)
            writeString(0x80, p0)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bytes32 p0, address p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(string,address,bool)`.
            mstore(0x00, 0xc91d5ed4)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, p2)
            writeString(0x80, p0)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bytes32 p0, address p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(string,address,uint256)`.
            mstore(0x00, 0x0d26b925)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, p2)
            writeString(0x80, p0)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bytes32 p0, address p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            // Selector of `log(string,address,string)`.
            mstore(0x00, 0xe0e9ad4f)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, 0xa0)
            writeString(0x80, p0)
            writeString(0xc0, p2)
        }
        _sendLogPayload(0x1c, 0xe4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
        }
    }

    function log(bytes32 p0, bool p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(string,bool,address)`.
            mstore(0x00, 0x932bbb38)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, p2)
            writeString(0x80, p0)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bytes32 p0, bool p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(string,bool,bool)`.
            mstore(0x00, 0x850b7ad6)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, p2)
            writeString(0x80, p0)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bytes32 p0, bool p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(string,bool,uint256)`.
            mstore(0x00, 0xc95958d6)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, p2)
            writeString(0x80, p0)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bytes32 p0, bool p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            // Selector of `log(string,bool,string)`.
            mstore(0x00, 0xe298f47d)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, 0xa0)
            writeString(0x80, p0)
            writeString(0xc0, p2)
        }
        _sendLogPayload(0x1c, 0xe4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
        }
    }

    function log(bytes32 p0, uint256 p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(string,uint256,address)`.
            mstore(0x00, 0x1c7ec448)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, p2)
            writeString(0x80, p0)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bytes32 p0, uint256 p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(string,uint256,bool)`.
            mstore(0x00, 0xca7733b1)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, p2)
            writeString(0x80, p0)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bytes32 p0, uint256 p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            // Selector of `log(string,uint256,uint256)`.
            mstore(0x00, 0xca47c4eb)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, p2)
            writeString(0x80, p0)
        }
        _sendLogPayload(0x1c, 0xa4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
        }
    }

    function log(bytes32 p0, uint256 p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            // Selector of `log(string,uint256,string)`.
            mstore(0x00, 0x5970e089)
            mstore(0x20, 0x60)
            mstore(0x40, p1)
            mstore(0x60, 0xa0)
            writeString(0x80, p0)
            writeString(0xc0, p2)
        }
        _sendLogPayload(0x1c, 0xe4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
        }
    }

    function log(bytes32 p0, bytes32 p1, address p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            // Selector of `log(string,string,address)`.
            mstore(0x00, 0x95ed0195)
            mstore(0x20, 0x60)
            mstore(0x40, 0xa0)
            mstore(0x60, p2)
            writeString(0x80, p0)
            writeString(0xc0, p1)
        }
        _sendLogPayload(0x1c, 0xe4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
        }
    }

    function log(bytes32 p0, bytes32 p1, bool p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            // Selector of `log(string,string,bool)`.
            mstore(0x00, 0xb0e0f9b5)
            mstore(0x20, 0x60)
            mstore(0x40, 0xa0)
            mstore(0x60, p2)
            writeString(0x80, p0)
            writeString(0xc0, p1)
        }
        _sendLogPayload(0x1c, 0xe4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
        }
    }

    function log(bytes32 p0, bytes32 p1, uint256 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            // Selector of `log(string,string,uint256)`.
            mstore(0x00, 0x5821efa1)
            mstore(0x20, 0x60)
            mstore(0x40, 0xa0)
            mstore(0x60, p2)
            writeString(0x80, p0)
            writeString(0xc0, p1)
        }
        _sendLogPayload(0x1c, 0xe4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
        }
    }

    function log(bytes32 p0, bytes32 p1, bytes32 p2) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            // Selector of `log(string,string,string)`.
            mstore(0x00, 0x2ced7cef)
            mstore(0x20, 0x60)
            mstore(0x40, 0xa0)
            mstore(0x60, 0xe0)
            writeString(0x80, p0)
            writeString(0xc0, p1)
            writeString(0x100, p2)
        }
        _sendLogPayload(0x1c, 0x124);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
        }
    }

    function log(address p0, address p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,address,address,address)`.
            mstore(0x00, 0x665bf134)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, address p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,address,address,bool)`.
            mstore(0x00, 0x0e378994)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, address p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,address,address,uint256)`.
            mstore(0x00, 0x94250d77)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, address p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,address,address,string)`.
            mstore(0x00, 0xf808da20)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, address p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,address,bool,address)`.
            mstore(0x00, 0x9f1bc36e)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, address p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,address,bool,bool)`.
            mstore(0x00, 0x2cd4134a)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,address,bool,uint256)`.
            mstore(0x00, 0x3971e78c)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, address p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,address,bool,string)`.
            mstore(0x00, 0xaa6540c8)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, address p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,address,uint256,address)`.
            mstore(0x00, 0x8da6def5)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,address,uint256,bool)`.
            mstore(0x00, 0x9b4254e2)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,address,uint256,uint256)`.
            mstore(0x00, 0xbe553481)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, address p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,address,uint256,string)`.
            mstore(0x00, 0xfdb4f990)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, address p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,address,string,address)`.
            mstore(0x00, 0x8f736d16)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, address p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,address,string,bool)`.
            mstore(0x00, 0x6f1a594e)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, address p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,address,string,uint256)`.
            mstore(0x00, 0xef1cefe7)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, address p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(address,address,string,string)`.
            mstore(0x00, 0x21bdaf25)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, 0xc0)
            writeString(0xa0, p2)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(address p0, bool p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,bool,address,address)`.
            mstore(0x00, 0x660375dd)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, bool p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,bool,address,bool)`.
            mstore(0x00, 0xa6f50b0f)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,bool,address,uint256)`.
            mstore(0x00, 0xa75c59de)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, bool p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,bool,address,string)`.
            mstore(0x00, 0x2dd778e6)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bool p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,bool,bool,address)`.
            mstore(0x00, 0xcf394485)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, bool p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,bool,bool,bool)`.
            mstore(0x00, 0xcac43479)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,bool,bool,uint256)`.
            mstore(0x00, 0x8c4e5de6)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, bool p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,bool,bool,string)`.
            mstore(0x00, 0xdfc4a2e8)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,bool,uint256,address)`.
            mstore(0x00, 0xccf790a1)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,bool,uint256,bool)`.
            mstore(0x00, 0xc4643e20)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,bool,uint256,uint256)`.
            mstore(0x00, 0x386ff5f4)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, bool p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,bool,uint256,string)`.
            mstore(0x00, 0x0aa6cfad)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bool p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,bool,string,address)`.
            mstore(0x00, 0x19fd4956)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bool p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,bool,string,bool)`.
            mstore(0x00, 0x50ad461d)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bool p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,bool,string,uint256)`.
            mstore(0x00, 0x80e6a20b)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bool p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(address,bool,string,string)`.
            mstore(0x00, 0x475c5c33)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, 0xc0)
            writeString(0xa0, p2)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(address p0, uint256 p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,uint256,address,address)`.
            mstore(0x00, 0x478d1c62)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,uint256,address,bool)`.
            mstore(0x00, 0xa1bcc9b3)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,uint256,address,uint256)`.
            mstore(0x00, 0x100f650e)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, uint256 p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,uint256,address,string)`.
            mstore(0x00, 0x1da986ea)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,uint256,bool,address)`.
            mstore(0x00, 0xa31bfdcc)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,uint256,bool,bool)`.
            mstore(0x00, 0x3bf5e537)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,uint256,bool,uint256)`.
            mstore(0x00, 0x22f6b999)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, uint256 p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,uint256,bool,string)`.
            mstore(0x00, 0xc5ad85f9)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,uint256,uint256,address)`.
            mstore(0x00, 0x20e3984d)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,uint256,uint256,bool)`.
            mstore(0x00, 0x66f1bc67)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(address,uint256,uint256,uint256)`.
            mstore(0x00, 0x34f0e636)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(address p0, uint256 p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,uint256,uint256,string)`.
            mstore(0x00, 0x4a28c017)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, uint256 p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,uint256,string,address)`.
            mstore(0x00, 0x5c430d47)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, uint256 p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,uint256,string,bool)`.
            mstore(0x00, 0xcf18105c)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, uint256 p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,uint256,string,uint256)`.
            mstore(0x00, 0xbf01f891)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, uint256 p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(address,uint256,string,string)`.
            mstore(0x00, 0x88a8c406)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, 0xc0)
            writeString(0xa0, p2)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(address p0, bytes32 p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,string,address,address)`.
            mstore(0x00, 0x0d36fa20)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bytes32 p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,string,address,bool)`.
            mstore(0x00, 0x0df12b76)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bytes32 p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,string,address,uint256)`.
            mstore(0x00, 0x457fe3cf)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bytes32 p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(address,string,address,string)`.
            mstore(0x00, 0xf7e36245)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p1)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(address p0, bytes32 p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,string,bool,address)`.
            mstore(0x00, 0x205871c2)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bytes32 p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,string,bool,bool)`.
            mstore(0x00, 0x5f1d5c9f)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bytes32 p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,string,bool,uint256)`.
            mstore(0x00, 0x515e38b6)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bytes32 p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(address,string,bool,string)`.
            mstore(0x00, 0xbc0b61fe)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p1)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(address p0, bytes32 p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,string,uint256,address)`.
            mstore(0x00, 0x63183678)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bytes32 p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,string,uint256,bool)`.
            mstore(0x00, 0x0ef7e050)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bytes32 p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(address,string,uint256,uint256)`.
            mstore(0x00, 0x1dc8e1b8)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(address p0, bytes32 p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(address,string,uint256,string)`.
            mstore(0x00, 0x448830a8)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p1)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(address p0, bytes32 p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(address,string,string,address)`.
            mstore(0x00, 0xa04e2f87)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(address p0, bytes32 p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(address,string,string,bool)`.
            mstore(0x00, 0x35a5071f)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(address p0, bytes32 p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(address,string,string,uint256)`.
            mstore(0x00, 0x159f8927)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(address p0, bytes32 p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(address,string,string,string)`.
            mstore(0x00, 0x5d02c50b)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, 0x100)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
            writeString(0x120, p3)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bool p0, address p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,address,address,address)`.
            mstore(0x00, 0x1d14d001)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, address p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,address,address,bool)`.
            mstore(0x00, 0x46600be0)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,address,address,uint256)`.
            mstore(0x00, 0x0c66d1be)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, address p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,address,address,string)`.
            mstore(0x00, 0xd812a167)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, address p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,address,bool,address)`.
            mstore(0x00, 0x1c41a336)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, address p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,address,bool,bool)`.
            mstore(0x00, 0x6a9c478b)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,address,bool,uint256)`.
            mstore(0x00, 0x07831502)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, address p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,address,bool,string)`.
            mstore(0x00, 0x4a66cb34)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,address,uint256,address)`.
            mstore(0x00, 0x136b05dd)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,address,uint256,bool)`.
            mstore(0x00, 0xd6019f1c)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,address,uint256,uint256)`.
            mstore(0x00, 0x7bf181a1)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, address p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,address,uint256,string)`.
            mstore(0x00, 0x51f09ff8)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, address p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,address,string,address)`.
            mstore(0x00, 0x6f7c603e)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, address p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,address,string,bool)`.
            mstore(0x00, 0xe2bfd60b)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, address p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,address,string,uint256)`.
            mstore(0x00, 0xc21f64c7)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, address p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(bool,address,string,string)`.
            mstore(0x00, 0xa73c1db6)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, 0xc0)
            writeString(0xa0, p2)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bool p0, bool p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,bool,address,address)`.
            mstore(0x00, 0xf4880ea4)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, bool p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,bool,address,bool)`.
            mstore(0x00, 0xc0a302d8)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,bool,address,uint256)`.
            mstore(0x00, 0x4c123d57)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, bool p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,bool,address,string)`.
            mstore(0x00, 0xa0a47963)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bool p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,bool,bool,address)`.
            mstore(0x00, 0x8c329b1a)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,bool,bool,bool)`.
            mstore(0x00, 0x3b2a5ce0)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,bool,bool,uint256)`.
            mstore(0x00, 0x6d7045c1)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, bool p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,bool,bool,string)`.
            mstore(0x00, 0x2ae408d4)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,bool,uint256,address)`.
            mstore(0x00, 0x54a7a9a0)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,bool,uint256,bool)`.
            mstore(0x00, 0x619e4d0e)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,bool,uint256,uint256)`.
            mstore(0x00, 0x0bb00eab)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, bool p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,bool,uint256,string)`.
            mstore(0x00, 0x7dd4d0e0)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bool p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,bool,string,address)`.
            mstore(0x00, 0xf9ad2b89)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bool p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,bool,string,bool)`.
            mstore(0x00, 0xb857163a)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bool p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,bool,string,uint256)`.
            mstore(0x00, 0xe3a9ca2f)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bool p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(bool,bool,string,string)`.
            mstore(0x00, 0x6d1e8751)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, 0xc0)
            writeString(0xa0, p2)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,uint256,address,address)`.
            mstore(0x00, 0x26f560a8)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,uint256,address,bool)`.
            mstore(0x00, 0xb4c314ff)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,uint256,address,uint256)`.
            mstore(0x00, 0x1537dc87)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, uint256 p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,uint256,address,string)`.
            mstore(0x00, 0x1bb3b09a)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,uint256,bool,address)`.
            mstore(0x00, 0x9acd3616)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,uint256,bool,bool)`.
            mstore(0x00, 0xceb5f4d7)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,uint256,bool,uint256)`.
            mstore(0x00, 0x7f9bbca2)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, uint256 p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,uint256,bool,string)`.
            mstore(0x00, 0x9143dbb1)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,uint256,uint256,address)`.
            mstore(0x00, 0x00dd87b9)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,uint256,uint256,bool)`.
            mstore(0x00, 0xbe984353)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(bool,uint256,uint256,uint256)`.
            mstore(0x00, 0x374bb4b2)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(bool p0, uint256 p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,uint256,uint256,string)`.
            mstore(0x00, 0x8e69fb5d)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, uint256 p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,uint256,string,address)`.
            mstore(0x00, 0xfedd1fff)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, uint256 p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,uint256,string,bool)`.
            mstore(0x00, 0xe5e70b2b)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, uint256 p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,uint256,string,uint256)`.
            mstore(0x00, 0x6a1199e2)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, uint256 p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(bool,uint256,string,string)`.
            mstore(0x00, 0xf5bc2249)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, 0xc0)
            writeString(0xa0, p2)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bool p0, bytes32 p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,string,address,address)`.
            mstore(0x00, 0x2b2b18dc)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bytes32 p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,string,address,bool)`.
            mstore(0x00, 0x6dd434ca)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bytes32 p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,string,address,uint256)`.
            mstore(0x00, 0xa5cada94)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bytes32 p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(bool,string,address,string)`.
            mstore(0x00, 0x12d6c788)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p1)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bool p0, bytes32 p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,string,bool,address)`.
            mstore(0x00, 0x538e06ab)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bytes32 p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,string,bool,bool)`.
            mstore(0x00, 0xdc5e935b)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bytes32 p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,string,bool,uint256)`.
            mstore(0x00, 0x1606a393)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bytes32 p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(bool,string,bool,string)`.
            mstore(0x00, 0x483d0416)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p1)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bool p0, bytes32 p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,string,uint256,address)`.
            mstore(0x00, 0x1596a1ce)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bytes32 p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,string,uint256,bool)`.
            mstore(0x00, 0x6b0e5d53)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bytes32 p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(bool,string,uint256,uint256)`.
            mstore(0x00, 0x28863fcb)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bool p0, bytes32 p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(bool,string,uint256,string)`.
            mstore(0x00, 0x1ad96de6)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p1)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bool p0, bytes32 p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(bool,string,string,address)`.
            mstore(0x00, 0x97d394d8)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bool p0, bytes32 p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(bool,string,string,bool)`.
            mstore(0x00, 0x1e4b87e5)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bool p0, bytes32 p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(bool,string,string,uint256)`.
            mstore(0x00, 0x7be0c3eb)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bool p0, bytes32 p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(bool,string,string,string)`.
            mstore(0x00, 0x1762e32a)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, 0x100)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
            writeString(0x120, p3)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(uint256 p0, address p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,address,address,address)`.
            mstore(0x00, 0x2488b414)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,address,address,bool)`.
            mstore(0x00, 0x091ffaf5)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,address,address,uint256)`.
            mstore(0x00, 0x736efbb6)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, address p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,address,address,string)`.
            mstore(0x00, 0x031c6f73)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,address,bool,address)`.
            mstore(0x00, 0xef72c513)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,address,bool,bool)`.
            mstore(0x00, 0xe351140f)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,address,bool,uint256)`.
            mstore(0x00, 0x5abd992a)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, address p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,address,bool,string)`.
            mstore(0x00, 0x90fb06aa)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,address,uint256,address)`.
            mstore(0x00, 0x15c127b5)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,address,uint256,bool)`.
            mstore(0x00, 0x5f743a7c)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,address,uint256,uint256)`.
            mstore(0x00, 0x0c9cd9c1)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, address p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,address,uint256,string)`.
            mstore(0x00, 0xddb06521)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, address p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,address,string,address)`.
            mstore(0x00, 0x9cba8fff)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, address p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,address,string,bool)`.
            mstore(0x00, 0xcc32ab07)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, address p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,address,string,uint256)`.
            mstore(0x00, 0x46826b5d)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, address p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(uint256,address,string,string)`.
            mstore(0x00, 0x3e128ca3)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, 0xc0)
            writeString(0xa0, p2)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,bool,address,address)`.
            mstore(0x00, 0xa1ef4cbb)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,bool,address,bool)`.
            mstore(0x00, 0x454d54a5)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,bool,address,uint256)`.
            mstore(0x00, 0x078287f5)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, bool p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,bool,address,string)`.
            mstore(0x00, 0xade052c7)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,bool,bool,address)`.
            mstore(0x00, 0x69640b59)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,bool,bool,bool)`.
            mstore(0x00, 0xb6f577a1)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,bool,bool,uint256)`.
            mstore(0x00, 0x7464ce23)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, bool p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,bool,bool,string)`.
            mstore(0x00, 0xdddb9561)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,bool,uint256,address)`.
            mstore(0x00, 0x88cb6041)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,bool,uint256,bool)`.
            mstore(0x00, 0x91a02e2a)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,bool,uint256,uint256)`.
            mstore(0x00, 0xc6acc7a8)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, bool p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,bool,uint256,string)`.
            mstore(0x00, 0xde03e774)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bool p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,bool,string,address)`.
            mstore(0x00, 0xef529018)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bool p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,bool,string,bool)`.
            mstore(0x00, 0xeb928d7f)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bool p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,bool,string,uint256)`.
            mstore(0x00, 0x2c1d0746)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bool p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(uint256,bool,string,string)`.
            mstore(0x00, 0x68c8b8bd)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, 0xc0)
            writeString(0xa0, p2)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,uint256,address,address)`.
            mstore(0x00, 0x56a5d1b1)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,uint256,address,bool)`.
            mstore(0x00, 0x15cac476)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,uint256,address,uint256)`.
            mstore(0x00, 0x88f6e4b2)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, uint256 p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,uint256,address,string)`.
            mstore(0x00, 0x6cde40b8)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,uint256,bool,address)`.
            mstore(0x00, 0x9a816a83)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,uint256,bool,bool)`.
            mstore(0x00, 0xab085ae6)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,uint256,bool,uint256)`.
            mstore(0x00, 0xeb7f6fd2)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, uint256 p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,uint256,bool,string)`.
            mstore(0x00, 0xa5b4fc99)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,uint256,uint256,address)`.
            mstore(0x00, 0xfa8185af)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,uint256,uint256,bool)`.
            mstore(0x00, 0xc598d185)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        assembly {
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            // Selector of `log(uint256,uint256,uint256,uint256)`.
            mstore(0x00, 0x193fb800)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
        }
        _sendLogPayload(0x1c, 0x84);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
        }
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,uint256,uint256,string)`.
            mstore(0x00, 0x59cfcbe3)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0x80)
            writeString(0xa0, p3)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, uint256 p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,uint256,string,address)`.
            mstore(0x00, 0x42d21db7)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, uint256 p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,uint256,string,bool)`.
            mstore(0x00, 0x7af6ab25)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, uint256 p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,uint256,string,uint256)`.
            mstore(0x00, 0x5da297eb)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, p3)
            writeString(0xa0, p2)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, uint256 p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(uint256,uint256,string,string)`.
            mstore(0x00, 0x27d8afd2)
            mstore(0x20, p0)
            mstore(0x40, p1)
            mstore(0x60, 0x80)
            mstore(0x80, 0xc0)
            writeString(0xa0, p2)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(uint256 p0, bytes32 p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,string,address,address)`.
            mstore(0x00, 0x6168ed61)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bytes32 p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,string,address,bool)`.
            mstore(0x00, 0x90c30a56)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bytes32 p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,string,address,uint256)`.
            mstore(0x00, 0xe8d3018d)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bytes32 p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(uint256,string,address,string)`.
            mstore(0x00, 0x9c3adfa1)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p1)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(uint256 p0, bytes32 p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,string,bool,address)`.
            mstore(0x00, 0xae2ec581)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bytes32 p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,string,bool,bool)`.
            mstore(0x00, 0xba535d9c)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bytes32 p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,string,bool,uint256)`.
            mstore(0x00, 0xcf009880)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bytes32 p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(uint256,string,bool,string)`.
            mstore(0x00, 0xd2d423cd)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p1)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(uint256 p0, bytes32 p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,string,uint256,address)`.
            mstore(0x00, 0x3b2279b4)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bytes32 p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,string,uint256,bool)`.
            mstore(0x00, 0x691a8f74)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bytes32 p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(uint256,string,uint256,uint256)`.
            mstore(0x00, 0x82c25b74)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p1)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(uint256 p0, bytes32 p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(uint256,string,uint256,string)`.
            mstore(0x00, 0xb7b914ca)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p1)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(uint256 p0, bytes32 p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(uint256,string,string,address)`.
            mstore(0x00, 0xd583c602)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(uint256 p0, bytes32 p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(uint256,string,string,bool)`.
            mstore(0x00, 0xb3a6b6bd)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(uint256 p0, bytes32 p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(uint256,string,string,uint256)`.
            mstore(0x00, 0xb028c9bd)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(uint256 p0, bytes32 p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(uint256,string,string,string)`.
            mstore(0x00, 0x21ad0683)
            mstore(0x20, p0)
            mstore(0x40, 0x80)
            mstore(0x60, 0xc0)
            mstore(0x80, 0x100)
            writeString(0xa0, p1)
            writeString(0xe0, p2)
            writeString(0x120, p3)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bytes32 p0, address p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,address,address,address)`.
            mstore(0x00, 0xed8f28f6)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, address p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,address,address,bool)`.
            mstore(0x00, 0xb59dbd60)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, address p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,address,address,uint256)`.
            mstore(0x00, 0x8ef3f399)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, address p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,address,address,string)`.
            mstore(0x00, 0x800a1c67)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p0)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, address p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,address,bool,address)`.
            mstore(0x00, 0x223603bd)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, address p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,address,bool,bool)`.
            mstore(0x00, 0x79884c2b)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, address p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,address,bool,uint256)`.
            mstore(0x00, 0x3e9f866a)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, address p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,address,bool,string)`.
            mstore(0x00, 0x0454c079)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p0)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, address p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,address,uint256,address)`.
            mstore(0x00, 0x63fb8bc5)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, address p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,address,uint256,bool)`.
            mstore(0x00, 0xfc4845f0)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, address p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,address,uint256,uint256)`.
            mstore(0x00, 0xf8f51b1e)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, address p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,address,uint256,string)`.
            mstore(0x00, 0x5a477632)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p0)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, address p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,address,string,address)`.
            mstore(0x00, 0xaabc9a31)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, address p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,address,string,bool)`.
            mstore(0x00, 0x5f15d28c)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, address p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,address,string,uint256)`.
            mstore(0x00, 0x91d1112e)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, address p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(string,address,string,string)`.
            mstore(0x00, 0x245986f2)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, 0x100)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
            writeString(0x120, p3)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bytes32 p0, bool p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,bool,address,address)`.
            mstore(0x00, 0x33e9dd1d)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, bool p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,bool,address,bool)`.
            mstore(0x00, 0x958c28c6)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, bool p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,bool,address,uint256)`.
            mstore(0x00, 0x5d08bb05)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, bool p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,bool,address,string)`.
            mstore(0x00, 0x2d8e33a4)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p0)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bool p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,bool,bool,address)`.
            mstore(0x00, 0x7190a529)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, bool p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,bool,bool,bool)`.
            mstore(0x00, 0x895af8c5)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, bool p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,bool,bool,uint256)`.
            mstore(0x00, 0x8e3f78a9)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, bool p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,bool,bool,string)`.
            mstore(0x00, 0x9d22d5dd)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p0)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bool p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,bool,uint256,address)`.
            mstore(0x00, 0x935e09bf)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, bool p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,bool,uint256,bool)`.
            mstore(0x00, 0x8af7cf8a)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,bool,uint256,uint256)`.
            mstore(0x00, 0x64b5bb67)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, bool p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,bool,uint256,string)`.
            mstore(0x00, 0x742d6ee7)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p0)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bool p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,bool,string,address)`.
            mstore(0x00, 0xe0625b29)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bool p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,bool,string,bool)`.
            mstore(0x00, 0x3f8a701d)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bool p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,bool,string,uint256)`.
            mstore(0x00, 0x24f91465)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bool p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(string,bool,string,string)`.
            mstore(0x00, 0xa826caeb)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, 0x100)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
            writeString(0x120, p3)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bytes32 p0, uint256 p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,uint256,address,address)`.
            mstore(0x00, 0x5ea2b7ae)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, uint256 p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,uint256,address,bool)`.
            mstore(0x00, 0x82112a42)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, uint256 p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,uint256,address,uint256)`.
            mstore(0x00, 0x4f04fdc6)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, uint256 p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,uint256,address,string)`.
            mstore(0x00, 0x9ffb2f93)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p0)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, uint256 p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,uint256,bool,address)`.
            mstore(0x00, 0xe0e95b98)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, uint256 p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,uint256,bool,bool)`.
            mstore(0x00, 0x354c36d6)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,uint256,bool,uint256)`.
            mstore(0x00, 0xe41b6f6f)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, uint256 p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,uint256,bool,string)`.
            mstore(0x00, 0xabf73a98)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p0)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, uint256 p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,uint256,uint256,address)`.
            mstore(0x00, 0xe21de278)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,uint256,uint256,bool)`.
            mstore(0x00, 0x7626db92)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            // Selector of `log(string,uint256,uint256,uint256)`.
            mstore(0x00, 0xa7a87853)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
        }
        _sendLogPayload(0x1c, 0xc4);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
        }
    }

    function log(bytes32 p0, uint256 p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,uint256,uint256,string)`.
            mstore(0x00, 0x854b3496)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, p2)
            mstore(0x80, 0xc0)
            writeString(0xa0, p0)
            writeString(0xe0, p3)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, uint256 p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,uint256,string,address)`.
            mstore(0x00, 0x7c4632a4)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, uint256 p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,uint256,string,bool)`.
            mstore(0x00, 0x7d24491d)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, uint256 p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,uint256,string,uint256)`.
            mstore(0x00, 0xc67ea9d1)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, uint256 p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(string,uint256,string,string)`.
            mstore(0x00, 0x5ab84e1f)
            mstore(0x20, 0x80)
            mstore(0x40, p1)
            mstore(0x60, 0xc0)
            mstore(0x80, 0x100)
            writeString(0xa0, p0)
            writeString(0xe0, p2)
            writeString(0x120, p3)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bytes32 p0, bytes32 p1, address p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,string,address,address)`.
            mstore(0x00, 0x439c7bef)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bytes32 p1, address p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,string,address,bool)`.
            mstore(0x00, 0x5ccd4e37)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bytes32 p1, address p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,string,address,uint256)`.
            mstore(0x00, 0x7cc3c607)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bytes32 p1, address p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(string,string,address,string)`.
            mstore(0x00, 0xeb1bff80)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, 0x100)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
            writeString(0x120, p3)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bytes32 p0, bytes32 p1, bool p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,string,bool,address)`.
            mstore(0x00, 0xc371c7db)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bytes32 p1, bool p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,string,bool,bool)`.
            mstore(0x00, 0x40785869)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bytes32 p1, bool p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,string,bool,uint256)`.
            mstore(0x00, 0xd6aefad2)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bytes32 p1, bool p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(string,string,bool,string)`.
            mstore(0x00, 0x5e84b0ea)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, 0x100)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
            writeString(0x120, p3)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bytes32 p0, bytes32 p1, uint256 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,string,uint256,address)`.
            mstore(0x00, 0x1023f7b2)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bytes32 p1, uint256 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,string,uint256,bool)`.
            mstore(0x00, 0xc3a8a654)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bytes32 p1, uint256 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            // Selector of `log(string,string,uint256,uint256)`.
            mstore(0x00, 0xf45d7d2c)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
        }
        _sendLogPayload(0x1c, 0x104);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
        }
    }

    function log(bytes32 p0, bytes32 p1, uint256 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(string,string,uint256,string)`.
            mstore(0x00, 0x5d1a971a)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, p2)
            mstore(0x80, 0x100)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
            writeString(0x120, p3)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bytes32 p0, bytes32 p1, bytes32 p2, address p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(string,string,string,address)`.
            mstore(0x00, 0x6d572f44)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, 0x100)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
            writeString(0x120, p2)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bytes32 p0, bytes32 p1, bytes32 p2, bool p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(string,string,string,bool)`.
            mstore(0x00, 0x2c1754ed)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, 0x100)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
            writeString(0x120, p2)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bytes32 p0, bytes32 p1, bytes32 p2, uint256 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            // Selector of `log(string,string,string,uint256)`.
            mstore(0x00, 0x8eafb02b)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, 0x100)
            mstore(0x80, p3)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
            writeString(0x120, p2)
        }
        _sendLogPayload(0x1c, 0x144);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
        }
    }

    function log(bytes32 p0, bytes32 p1, bytes32 p2, bytes32 p3) internal pure {
        bytes32 m0;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 m5;
        bytes32 m6;
        bytes32 m7;
        bytes32 m8;
        bytes32 m9;
        bytes32 m10;
        bytes32 m11;
        bytes32 m12;
        assembly {
            function writeString(pos, w) {
                let length := 0
                for {} lt(length, 0x20) { length := add(length, 1) } { if iszero(byte(length, w)) { break } }
                mstore(pos, length)
                let shift := sub(256, shl(3, length))
                mstore(add(pos, 0x20), shl(shift, shr(shift, w)))
            }
            m0 := mload(0x00)
            m1 := mload(0x20)
            m2 := mload(0x40)
            m3 := mload(0x60)
            m4 := mload(0x80)
            m5 := mload(0xa0)
            m6 := mload(0xc0)
            m7 := mload(0xe0)
            m8 := mload(0x100)
            m9 := mload(0x120)
            m10 := mload(0x140)
            m11 := mload(0x160)
            m12 := mload(0x180)
            // Selector of `log(string,string,string,string)`.
            mstore(0x00, 0xde68f20a)
            mstore(0x20, 0x80)
            mstore(0x40, 0xc0)
            mstore(0x60, 0x100)
            mstore(0x80, 0x140)
            writeString(0xa0, p0)
            writeString(0xe0, p1)
            writeString(0x120, p2)
            writeString(0x160, p3)
        }
        _sendLogPayload(0x1c, 0x184);
        assembly {
            mstore(0x00, m0)
            mstore(0x20, m1)
            mstore(0x40, m2)
            mstore(0x60, m3)
            mstore(0x80, m4)
            mstore(0xa0, m5)
            mstore(0xc0, m6)
            mstore(0xe0, m7)
            mstore(0x100, m8)
            mstore(0x120, m9)
            mstore(0x140, m10)
            mstore(0x160, m11)
            mstore(0x180, m12)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {VmSafe} from "./Vm.sol";

/**
 * StdChains provides information about EVM compatible chains that can be used in scripts/tests.
 * For each chain, the chain's name, chain ID, and a default RPC URL are provided. Chains are
 * identified by their alias, which is the same as the alias in the `[rpc_endpoints]` section of
 * the `foundry.toml` file. For best UX, ensure the alias in the `foundry.toml` file match the
 * alias used in this contract, which can be found as the first argument to the
 * `setChainWithDefaultRpcUrl` call in the `initializeStdChains` function.
 *
 * There are two main ways to use this contract:
 *   1. Set a chain with `setChain(string memory chainAlias, ChainData memory chain)` or
 *      `setChain(string memory chainAlias, Chain memory chain)`
 *   2. Get a chain with `getChain(string memory chainAlias)` or `getChain(uint256 chainId)`.
 *
 * The first time either of those are used, chains are initialized with the default set of RPC URLs.
 * This is done in `initializeStdChains`, which uses `setChainWithDefaultRpcUrl`. Defaults are recorded in
 * `defaultRpcUrls`.
 *
 * The `setChain` function is straightforward, and it simply saves off the given chain data.
 *
 * The `getChain` methods use `getChainWithUpdatedRpcUrl` to return a chain. For example, let's say
 * we want to retrieve the RPC URL for `mainnet`:
 *   - If you have specified data with `setChain`, it will return that.
 *   - If you have configured a mainnet RPC URL in `foundry.toml`, it will return the URL, provided it
 *     is valid (e.g. a URL is specified, or an environment variable is given and exists).
 *   - If neither of the above conditions is met, the default data is returned.
 *
 * Summarizing the above, the prioritization hierarchy is `setChain` -> `foundry.toml` -> environment variable -> defaults.
 */
abstract contract StdChains {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    bool private stdChainsInitialized;

    struct ChainData {
        string name;
        uint256 chainId;
        string rpcUrl;
    }

    struct Chain {
        // The chain name.
        string name;
        // The chain's Chain ID.
        uint256 chainId;
        // The chain's alias. (i.e. what gets specified in `foundry.toml`).
        string chainAlias;
        // A default RPC endpoint for this chain.
        // NOTE: This default RPC URL is included for convenience to facilitate quick tests and
        // experimentation. Do not use this RPC URL for production test suites, CI, or other heavy
        // usage as you will be throttled and this is a disservice to others who need this endpoint.
        string rpcUrl;
    }

    // Maps from the chain's alias (matching the alias in the `foundry.toml` file) to chain data.
    mapping(string => Chain) private chains;
    // Maps from the chain's alias to it's default RPC URL.
    mapping(string => string) private defaultRpcUrls;
    // Maps from a chain ID to it's alias.
    mapping(uint256 => string) private idToAlias;

    bool private fallbackToDefaultRpcUrls = true;

    // The RPC URL will be fetched from config or defaultRpcUrls if possible.
    function getChain(string memory chainAlias) internal virtual returns (Chain memory chain) {
        require(bytes(chainAlias).length != 0, "StdChains getChain(string): Chain alias cannot be the empty string.");

        initializeStdChains();
        chain = chains[chainAlias];
        require(
            chain.chainId != 0,
            string(abi.encodePacked("StdChains getChain(string): Chain with alias \"", chainAlias, "\" not found."))
        );

        chain = getChainWithUpdatedRpcUrl(chainAlias, chain);
    }

    function getChain(uint256 chainId) internal virtual returns (Chain memory chain) {
        require(chainId != 0, "StdChains getChain(uint256): Chain ID cannot be 0.");
        initializeStdChains();
        string memory chainAlias = idToAlias[chainId];

        chain = chains[chainAlias];

        require(
            chain.chainId != 0,
            string(abi.encodePacked("StdChains getChain(uint256): Chain with ID ", vm.toString(chainId), " not found."))
        );

        chain = getChainWithUpdatedRpcUrl(chainAlias, chain);
    }

    // set chain info, with priority to argument's rpcUrl field.
    function setChain(string memory chainAlias, ChainData memory chain) internal virtual {
        require(
            bytes(chainAlias).length != 0,
            "StdChains setChain(string,ChainData): Chain alias cannot be the empty string."
        );

        require(chain.chainId != 0, "StdChains setChain(string,ChainData): Chain ID cannot be 0.");

        initializeStdChains();
        string memory foundAlias = idToAlias[chain.chainId];

        require(
            bytes(foundAlias).length == 0 || keccak256(bytes(foundAlias)) == keccak256(bytes(chainAlias)),
            string(
                abi.encodePacked(
                    "StdChains setChain(string,ChainData): Chain ID ",
                    vm.toString(chain.chainId),
                    " already used by \"",
                    foundAlias,
                    "\"."
                )
            )
        );

        uint256 oldChainId = chains[chainAlias].chainId;
        delete idToAlias[oldChainId];

        chains[chainAlias] =
            Chain({name: chain.name, chainId: chain.chainId, chainAlias: chainAlias, rpcUrl: chain.rpcUrl});
        idToAlias[chain.chainId] = chainAlias;
    }

    // set chain info, with priority to argument's rpcUrl field.
    function setChain(string memory chainAlias, Chain memory chain) internal virtual {
        setChain(chainAlias, ChainData({name: chain.name, chainId: chain.chainId, rpcUrl: chain.rpcUrl}));
    }

    function _toUpper(string memory str) private pure returns (string memory) {
        bytes memory strb = bytes(str);
        bytes memory copy = new bytes(strb.length);
        for (uint256 i = 0; i < strb.length; i++) {
            bytes1 b = strb[i];
            if (b >= 0x61 && b <= 0x7A) {
                copy[i] = bytes1(uint8(b) - 32);
            } else {
                copy[i] = b;
            }
        }
        return string(copy);
    }

    // lookup rpcUrl, in descending order of priority:
    // current -> config (foundry.toml) -> environment variable -> default
    function getChainWithUpdatedRpcUrl(string memory chainAlias, Chain memory chain) private returns (Chain memory) {
        if (bytes(chain.rpcUrl).length == 0) {
            try vm.rpcUrl(chainAlias) returns (string memory configRpcUrl) {
                chain.rpcUrl = configRpcUrl;
            } catch (bytes memory err) {
                string memory envName = string(abi.encodePacked(_toUpper(chainAlias), "_RPC_URL"));
                if (fallbackToDefaultRpcUrls) {
                    chain.rpcUrl = vm.envOr(envName, defaultRpcUrls[chainAlias]);
                } else {
                    chain.rpcUrl = vm.envString(envName);
                }
                // distinguish 'not found' from 'cannot read'
                bytes memory notFoundError =
                    abi.encodeWithSignature("CheatCodeError", string(abi.encodePacked("invalid rpc url ", chainAlias)));
                if (keccak256(notFoundError) != keccak256(err) || bytes(chain.rpcUrl).length == 0) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, err), mload(err))
                    }
                }
            }
        }
        return chain;
    }

    function setFallbackToDefaultRpcUrls(bool useDefault) internal {
        fallbackToDefaultRpcUrls = useDefault;
    }

    function initializeStdChains() private {
        if (stdChainsInitialized) return;

        stdChainsInitialized = true;

        // If adding an RPC here, make sure to test the default RPC URL in `testRpcs`
        setChainWithDefaultRpcUrl("anvil", ChainData("Anvil", 31337, "http://127.0.0.1:8545"));
        setChainWithDefaultRpcUrl(
            "mainnet", ChainData("Mainnet", 1, "https://mainnet.infura.io/v3/b9794ad1ddf84dfb8c34d6bb5dca2001")
        );
        setChainWithDefaultRpcUrl(
            "goerli", ChainData("Goerli", 5, "https://goerli.infura.io/v3/b9794ad1ddf84dfb8c34d6bb5dca2001")
        );
        setChainWithDefaultRpcUrl(
            "sepolia", ChainData("Sepolia", 11155111, "https://sepolia.infura.io/v3/b9794ad1ddf84dfb8c34d6bb5dca2001")
        );
        setChainWithDefaultRpcUrl("optimism", ChainData("Optimism", 10, "https://mainnet.optimism.io"));
        setChainWithDefaultRpcUrl("optimism_goerli", ChainData("Optimism Goerli", 420, "https://goerli.optimism.io"));
        setChainWithDefaultRpcUrl("arbitrum_one", ChainData("Arbitrum One", 42161, "https://arb1.arbitrum.io/rpc"));
        setChainWithDefaultRpcUrl(
            "arbitrum_one_goerli", ChainData("Arbitrum One Goerli", 421613, "https://goerli-rollup.arbitrum.io/rpc")
        );
        setChainWithDefaultRpcUrl("arbitrum_nova", ChainData("Arbitrum Nova", 42170, "https://nova.arbitrum.io/rpc"));
        setChainWithDefaultRpcUrl("polygon", ChainData("Polygon", 137, "https://polygon-rpc.com"));
        setChainWithDefaultRpcUrl(
            "polygon_mumbai", ChainData("Polygon Mumbai", 80001, "https://rpc-mumbai.maticvigil.com")
        );
        setChainWithDefaultRpcUrl("avalanche", ChainData("Avalanche", 43114, "https://api.avax.network/ext/bc/C/rpc"));
        setChainWithDefaultRpcUrl(
            "avalanche_fuji", ChainData("Avalanche Fuji", 43113, "https://api.avax-test.network/ext/bc/C/rpc")
        );
        setChainWithDefaultRpcUrl(
            "bnb_smart_chain", ChainData("BNB Smart Chain", 56, "https://bsc-dataseed1.binance.org")
        );
        setChainWithDefaultRpcUrl(
            "bnb_smart_chain_testnet",
            ChainData("BNB Smart Chain Testnet", 97, "https://rpc.ankr.com/bsc_testnet_chapel")
        );
        setChainWithDefaultRpcUrl("gnosis_chain", ChainData("Gnosis Chain", 100, "https://rpc.gnosischain.com"));
    }

    // set chain info, with priority to chainAlias' rpc url in foundry.toml
    function setChainWithDefaultRpcUrl(string memory chainAlias, ChainData memory chain) private {
        string memory rpcUrl = chain.rpcUrl;
        defaultRpcUrls[chainAlias] = rpcUrl;
        chain.rpcUrl = "";
        setChain(chainAlias, chain);
        chain.rpcUrl = rpcUrl; // restore argument
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

import {StdStorage, stdStorage} from "./StdStorage.sol";
import {Vm} from "./Vm.sol";

abstract contract StdCheatsSafe {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    uint256 private constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    bool private gasMeteringOff;

    // Data structures to parse Transaction objects from the broadcast artifact
    // that conform to EIP1559. The Raw structs is what is parsed from the JSON
    // and then converted to the one that is used by the user for better UX.

    struct RawTx1559 {
        string[] arguments;
        address contractAddress;
        string contractName;
        // json value name = function
        string functionSig;
        bytes32 hash;
        // json value name = tx
        RawTx1559Detail txDetail;
        // json value name = type
        string opcode;
    }

    struct RawTx1559Detail {
        AccessList[] accessList;
        bytes data;
        address from;
        bytes gas;
        bytes nonce;
        address to;
        bytes txType;
        bytes value;
    }

    struct Tx1559 {
        string[] arguments;
        address contractAddress;
        string contractName;
        string functionSig;
        bytes32 hash;
        Tx1559Detail txDetail;
        string opcode;
    }

    struct Tx1559Detail {
        AccessList[] accessList;
        bytes data;
        address from;
        uint256 gas;
        uint256 nonce;
        address to;
        uint256 txType;
        uint256 value;
    }

    // Data structures to parse Transaction objects from the broadcast artifact
    // that DO NOT conform to EIP1559. The Raw structs is what is parsed from the JSON
    // and then converted to the one that is used by the user for better UX.

    struct TxLegacy {
        string[] arguments;
        address contractAddress;
        string contractName;
        string functionSig;
        string hash;
        string opcode;
        TxDetailLegacy transaction;
    }

    struct TxDetailLegacy {
        AccessList[] accessList;
        uint256 chainId;
        bytes data;
        address from;
        uint256 gas;
        uint256 gasPrice;
        bytes32 hash;
        uint256 nonce;
        bytes1 opcode;
        bytes32 r;
        bytes32 s;
        uint256 txType;
        address to;
        uint8 v;
        uint256 value;
    }

    struct AccessList {
        address accessAddress;
        bytes32[] storageKeys;
    }

    // Data structures to parse Receipt objects from the broadcast artifact.
    // The Raw structs is what is parsed from the JSON
    // and then converted to the one that is used by the user for better UX.

    struct RawReceipt {
        bytes32 blockHash;
        bytes blockNumber;
        address contractAddress;
        bytes cumulativeGasUsed;
        bytes effectiveGasPrice;
        address from;
        bytes gasUsed;
        RawReceiptLog[] logs;
        bytes logsBloom;
        bytes status;
        address to;
        bytes32 transactionHash;
        bytes transactionIndex;
    }

    struct Receipt {
        bytes32 blockHash;
        uint256 blockNumber;
        address contractAddress;
        uint256 cumulativeGasUsed;
        uint256 effectiveGasPrice;
        address from;
        uint256 gasUsed;
        ReceiptLog[] logs;
        bytes logsBloom;
        uint256 status;
        address to;
        bytes32 transactionHash;
        uint256 transactionIndex;
    }

    // Data structures to parse the entire broadcast artifact, assuming the
    // transactions conform to EIP1559.

    struct EIP1559ScriptArtifact {
        string[] libraries;
        string path;
        string[] pending;
        Receipt[] receipts;
        uint256 timestamp;
        Tx1559[] transactions;
        TxReturn[] txReturns;
    }

    struct RawEIP1559ScriptArtifact {
        string[] libraries;
        string path;
        string[] pending;
        RawReceipt[] receipts;
        TxReturn[] txReturns;
        uint256 timestamp;
        RawTx1559[] transactions;
    }

    struct RawReceiptLog {
        // json value = address
        address logAddress;
        bytes32 blockHash;
        bytes blockNumber;
        bytes data;
        bytes logIndex;
        bool removed;
        bytes32[] topics;
        bytes32 transactionHash;
        bytes transactionIndex;
        bytes transactionLogIndex;
    }

    struct ReceiptLog {
        // json value = address
        address logAddress;
        bytes32 blockHash;
        uint256 blockNumber;
        bytes data;
        uint256 logIndex;
        bytes32[] topics;
        uint256 transactionIndex;
        uint256 transactionLogIndex;
        bool removed;
    }

    struct TxReturn {
        string internalType;
        string value;
    }

    struct Account {
        address addr;
        uint256 key;
    }

    enum AddressType {
        Payable,
        NonPayable,
        ZeroAddress,
        Precompile,
        ForgeAddress
    }

    // Checks that `addr` is not blacklisted by token contracts that have a blacklist.
    function assumeNotBlacklisted(address token, address addr) internal view virtual {
        // Nothing to check if `token` is not a contract.
        uint256 tokenCodeSize;
        assembly {
            tokenCodeSize := extcodesize(token)
        }
        require(tokenCodeSize > 0, "StdCheats assumeNotBlacklisted(address,address): Token address is not a contract.");

        bool success;
        bytes memory returnData;

        // 4-byte selector for `isBlacklisted(address)`, used by USDC.
        (success, returnData) = token.staticcall(abi.encodeWithSelector(0xfe575a87, addr));
        vm.assume(!success || abi.decode(returnData, (bool)) == false);

        // 4-byte selector for `isBlackListed(address)`, used by USDT.
        (success, returnData) = token.staticcall(abi.encodeWithSelector(0xe47d6060, addr));
        vm.assume(!success || abi.decode(returnData, (bool)) == false);
    }

    // Checks that `addr` is not blacklisted by token contracts that have a blacklist.
    // This is identical to `assumeNotBlacklisted(address,address)` but with a different name, for
    // backwards compatibility, since this name was used in the original PR which has already has
    // a release. This function can be removed in a future release once we want a breaking change.
    function assumeNoBlacklisted(address token, address addr) internal view virtual {
        assumeNotBlacklisted(token, addr);
    }

    function assumeAddressIsNot(address addr, AddressType addressType) internal virtual {
        if (addressType == AddressType.Payable) {
            assumeNotPayable(addr);
        } else if (addressType == AddressType.NonPayable) {
            assumePayable(addr);
        } else if (addressType == AddressType.ZeroAddress) {
            assumeNotZeroAddress(addr);
        } else if (addressType == AddressType.Precompile) {
            assumeNotPrecompile(addr);
        } else if (addressType == AddressType.ForgeAddress) {
            assumeNotForgeAddress(addr);
        }
    }

    function assumeAddressIsNot(address addr, AddressType addressType1, AddressType addressType2) internal virtual {
        assumeAddressIsNot(addr, addressType1);
        assumeAddressIsNot(addr, addressType2);
    }

    function assumeAddressIsNot(
        address addr,
        AddressType addressType1,
        AddressType addressType2,
        AddressType addressType3
    ) internal virtual {
        assumeAddressIsNot(addr, addressType1);
        assumeAddressIsNot(addr, addressType2);
        assumeAddressIsNot(addr, addressType3);
    }

    function assumeAddressIsNot(
        address addr,
        AddressType addressType1,
        AddressType addressType2,
        AddressType addressType3,
        AddressType addressType4
    ) internal virtual {
        assumeAddressIsNot(addr, addressType1);
        assumeAddressIsNot(addr, addressType2);
        assumeAddressIsNot(addr, addressType3);
        assumeAddressIsNot(addr, addressType4);
    }

    // This function checks whether an address, `addr`, is payable. It works by sending 1 wei to
    // `addr` and checking the `success` return value.
    // NOTE: This function may result in state changes depending on the fallback/receive logic
    // implemented by `addr`, which should be taken into account when this function is used.
    function _isPayable(address addr) private returns (bool) {
        require(
            addr.balance < UINT256_MAX,
            "StdCheats _isPayable(address): Balance equals max uint256, so it cannot receive any more funds"
        );
        uint256 origBalanceTest = address(this).balance;
        uint256 origBalanceAddr = address(addr).balance;

        vm.deal(address(this), 1);
        (bool success,) = payable(addr).call{value: 1}("");

        // reset balances
        vm.deal(address(this), origBalanceTest);
        vm.deal(addr, origBalanceAddr);

        return success;
    }

    // NOTE: This function may result in state changes depending on the fallback/receive logic
    // implemented by `addr`, which should be taken into account when this function is used. See the
    // `_isPayable` method for more information.
    function assumePayable(address addr) internal virtual {
        vm.assume(_isPayable(addr));
    }

    function assumeNotPayable(address addr) internal virtual {
        vm.assume(!_isPayable(addr));
    }

    function assumeNotZeroAddress(address addr) internal pure virtual {
        vm.assume(addr != address(0));
    }

    function assumeNotPrecompile(address addr) internal pure virtual {
        assumeNotPrecompile(addr, _pureChainId());
    }

    function assumeNotPrecompile(address addr, uint256 chainId) internal pure virtual {
        // Note: For some chains like Optimism these are technically predeploys (i.e. bytecode placed at a specific
        // address), but the same rationale for excluding them applies so we include those too.

        // These should be present on all EVM-compatible chains.
        vm.assume(addr < address(0x1) || addr > address(0x9));

        // forgefmt: disable-start
        if (chainId == 10 || chainId == 420) {
            // https://github.com/ethereum-optimism/optimism/blob/eaa371a0184b56b7ca6d9eb9cb0a2b78b2ccd864/op-bindings/predeploys/addresses.go#L6-L21
            vm.assume(addr < address(0x4200000000000000000000000000000000000000) || addr > address(0x4200000000000000000000000000000000000800));
        } else if (chainId == 42161 || chainId == 421613) {
            // https://developer.arbitrum.io/useful-addresses#arbitrum-precompiles-l2-same-on-all-arb-chains
            vm.assume(addr < address(0x0000000000000000000000000000000000000064) || addr > address(0x0000000000000000000000000000000000000068));
        } else if (chainId == 43114 || chainId == 43113) {
            // https://github.com/ava-labs/subnet-evm/blob/47c03fd007ecaa6de2c52ea081596e0a88401f58/precompile/params.go#L18-L59
            vm.assume(addr < address(0x0100000000000000000000000000000000000000) || addr > address(0x01000000000000000000000000000000000000ff));
            vm.assume(addr < address(0x0200000000000000000000000000000000000000) || addr > address(0x02000000000000000000000000000000000000FF));
            vm.assume(addr < address(0x0300000000000000000000000000000000000000) || addr > address(0x03000000000000000000000000000000000000Ff));
        }
        // forgefmt: disable-end
    }

    function assumeNotForgeAddress(address addr) internal pure virtual {
        // vm and console addresses
        vm.assume(addr != address(vm) || addr != 0x000000000000000000636F6e736F6c652e6c6f67);
    }

    function readEIP1559ScriptArtifact(string memory path)
        internal
        view
        virtual
        returns (EIP1559ScriptArtifact memory)
    {
        string memory data = vm.readFile(path);
        bytes memory parsedData = vm.parseJson(data);
        RawEIP1559ScriptArtifact memory rawArtifact = abi.decode(parsedData, (RawEIP1559ScriptArtifact));
        EIP1559ScriptArtifact memory artifact;
        artifact.libraries = rawArtifact.libraries;
        artifact.path = rawArtifact.path;
        artifact.timestamp = rawArtifact.timestamp;
        artifact.pending = rawArtifact.pending;
        artifact.txReturns = rawArtifact.txReturns;
        artifact.receipts = rawToConvertedReceipts(rawArtifact.receipts);
        artifact.transactions = rawToConvertedEIPTx1559s(rawArtifact.transactions);
        return artifact;
    }

    function rawToConvertedEIPTx1559s(RawTx1559[] memory rawTxs) internal pure virtual returns (Tx1559[] memory) {
        Tx1559[] memory txs = new Tx1559[](rawTxs.length);
        for (uint256 i; i < rawTxs.length; i++) {
            txs[i] = rawToConvertedEIPTx1559(rawTxs[i]);
        }
        return txs;
    }

    function rawToConvertedEIPTx1559(RawTx1559 memory rawTx) internal pure virtual returns (Tx1559 memory) {
        Tx1559 memory transaction;
        transaction.arguments = rawTx.arguments;
        transaction.contractName = rawTx.contractName;
        transaction.functionSig = rawTx.functionSig;
        transaction.hash = rawTx.hash;
        transaction.txDetail = rawToConvertedEIP1559Detail(rawTx.txDetail);
        transaction.opcode = rawTx.opcode;
        return transaction;
    }

    function rawToConvertedEIP1559Detail(RawTx1559Detail memory rawDetail)
        internal
        pure
        virtual
        returns (Tx1559Detail memory)
    {
        Tx1559Detail memory txDetail;
        txDetail.data = rawDetail.data;
        txDetail.from = rawDetail.from;
        txDetail.to = rawDetail.to;
        txDetail.nonce = _bytesToUint(rawDetail.nonce);
        txDetail.txType = _bytesToUint(rawDetail.txType);
        txDetail.value = _bytesToUint(rawDetail.value);
        txDetail.gas = _bytesToUint(rawDetail.gas);
        txDetail.accessList = rawDetail.accessList;
        return txDetail;
    }

    function readTx1559s(string memory path) internal view virtual returns (Tx1559[] memory) {
        string memory deployData = vm.readFile(path);
        bytes memory parsedDeployData = vm.parseJson(deployData, ".transactions");
        RawTx1559[] memory rawTxs = abi.decode(parsedDeployData, (RawTx1559[]));
        return rawToConvertedEIPTx1559s(rawTxs);
    }

    function readTx1559(string memory path, uint256 index) internal view virtual returns (Tx1559 memory) {
        string memory deployData = vm.readFile(path);
        string memory key = string(abi.encodePacked(".transactions[", vm.toString(index), "]"));
        bytes memory parsedDeployData = vm.parseJson(deployData, key);
        RawTx1559 memory rawTx = abi.decode(parsedDeployData, (RawTx1559));
        return rawToConvertedEIPTx1559(rawTx);
    }

    // Analogous to readTransactions, but for receipts.
    function readReceipts(string memory path) internal view virtual returns (Receipt[] memory) {
        string memory deployData = vm.readFile(path);
        bytes memory parsedDeployData = vm.parseJson(deployData, ".receipts");
        RawReceipt[] memory rawReceipts = abi.decode(parsedDeployData, (RawReceipt[]));
        return rawToConvertedReceipts(rawReceipts);
    }

    function readReceipt(string memory path, uint256 index) internal view virtual returns (Receipt memory) {
        string memory deployData = vm.readFile(path);
        string memory key = string(abi.encodePacked(".receipts[", vm.toString(index), "]"));
        bytes memory parsedDeployData = vm.parseJson(deployData, key);
        RawReceipt memory rawReceipt = abi.decode(parsedDeployData, (RawReceipt));
        return rawToConvertedReceipt(rawReceipt);
    }

    function rawToConvertedReceipts(RawReceipt[] memory rawReceipts) internal pure virtual returns (Receipt[] memory) {
        Receipt[] memory receipts = new Receipt[](rawReceipts.length);
        for (uint256 i; i < rawReceipts.length; i++) {
            receipts[i] = rawToConvertedReceipt(rawReceipts[i]);
        }
        return receipts;
    }

    function rawToConvertedReceipt(RawReceipt memory rawReceipt) internal pure virtual returns (Receipt memory) {
        Receipt memory receipt;
        receipt.blockHash = rawReceipt.blockHash;
        receipt.to = rawReceipt.to;
        receipt.from = rawReceipt.from;
        receipt.contractAddress = rawReceipt.contractAddress;
        receipt.effectiveGasPrice = _bytesToUint(rawReceipt.effectiveGasPrice);
        receipt.cumulativeGasUsed = _bytesToUint(rawReceipt.cumulativeGasUsed);
        receipt.gasUsed = _bytesToUint(rawReceipt.gasUsed);
        receipt.status = _bytesToUint(rawReceipt.status);
        receipt.transactionIndex = _bytesToUint(rawReceipt.transactionIndex);
        receipt.blockNumber = _bytesToUint(rawReceipt.blockNumber);
        receipt.logs = rawToConvertedReceiptLogs(rawReceipt.logs);
        receipt.logsBloom = rawReceipt.logsBloom;
        receipt.transactionHash = rawReceipt.transactionHash;
        return receipt;
    }

    function rawToConvertedReceiptLogs(RawReceiptLog[] memory rawLogs)
        internal
        pure
        virtual
        returns (ReceiptLog[] memory)
    {
        ReceiptLog[] memory logs = new ReceiptLog[](rawLogs.length);
        for (uint256 i; i < rawLogs.length; i++) {
            logs[i].logAddress = rawLogs[i].logAddress;
            logs[i].blockHash = rawLogs[i].blockHash;
            logs[i].blockNumber = _bytesToUint(rawLogs[i].blockNumber);
            logs[i].data = rawLogs[i].data;
            logs[i].logIndex = _bytesToUint(rawLogs[i].logIndex);
            logs[i].topics = rawLogs[i].topics;
            logs[i].transactionIndex = _bytesToUint(rawLogs[i].transactionIndex);
            logs[i].transactionLogIndex = _bytesToUint(rawLogs[i].transactionLogIndex);
            logs[i].removed = rawLogs[i].removed;
        }
        return logs;
    }

    // Deploy a contract by fetching the contract bytecode from
    // the artifacts directory
    // e.g. `deployCode(code, abi.encode(arg1,arg2,arg3))`
    function deployCode(string memory what, bytes memory args) internal virtual returns (address addr) {
        bytes memory bytecode = abi.encodePacked(vm.getCode(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string,bytes): Deployment failed.");
    }

    function deployCode(string memory what) internal virtual returns (address addr) {
        bytes memory bytecode = vm.getCode(what);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string): Deployment failed.");
    }

    /// @dev deploy contract with value on construction
    function deployCode(string memory what, bytes memory args, uint256 val) internal virtual returns (address addr) {
        bytes memory bytecode = abi.encodePacked(vm.getCode(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(val, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string,bytes,uint256): Deployment failed.");
    }

    function deployCode(string memory what, uint256 val) internal virtual returns (address addr) {
        bytes memory bytecode = vm.getCode(what);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(val, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string,uint256): Deployment failed.");
    }

    // creates a labeled address and the corresponding private key
    function makeAddrAndKey(string memory name) internal virtual returns (address addr, uint256 privateKey) {
        privateKey = uint256(keccak256(abi.encodePacked(name)));
        addr = vm.addr(privateKey);
        vm.label(addr, name);
    }

    // creates a labeled address
    function makeAddr(string memory name) internal virtual returns (address addr) {
        (addr,) = makeAddrAndKey(name);
    }

    // Destroys an account immediately, sending the balance to beneficiary.
    // Destroying means: balance will be zero, code will be empty, and nonce will be 0
    // This is similar to selfdestruct but not identical: selfdestruct destroys code and nonce
    // only after tx ends, this will run immediately.
    function destroyAccount(address who, address beneficiary) internal virtual {
        uint256 currBalance = who.balance;
        vm.etch(who, abi.encode());
        vm.deal(who, 0);
        vm.resetNonce(who);

        uint256 beneficiaryBalance = beneficiary.balance;
        vm.deal(beneficiary, currBalance + beneficiaryBalance);
    }

    // creates a struct containing both a labeled address and the corresponding private key
    function makeAccount(string memory name) internal virtual returns (Account memory account) {
        (account.addr, account.key) = makeAddrAndKey(name);
    }

    function deriveRememberKey(string memory mnemonic, uint32 index)
        internal
        virtual
        returns (address who, uint256 privateKey)
    {
        privateKey = vm.deriveKey(mnemonic, index);
        who = vm.rememberKey(privateKey);
    }

    function _bytesToUint(bytes memory b) private pure returns (uint256) {
        require(b.length <= 32, "StdCheats _bytesToUint(bytes): Bytes length exceeds 32.");
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }

    function isFork() internal view virtual returns (bool status) {
        try vm.activeFork() {
            status = true;
        } catch (bytes memory) {}
    }

    modifier skipWhenForking() {
        if (!isFork()) {
            _;
        }
    }

    modifier skipWhenNotForking() {
        if (isFork()) {
            _;
        }
    }

    modifier noGasMetering() {
        vm.pauseGasMetering();
        // To prevent turning gas monitoring back on with nested functions that use this modifier,
        // we check if gasMetering started in the off position. If it did, we don't want to turn
        // it back on until we exit the top level function that used the modifier
        //
        // i.e. funcA() noGasMetering { funcB() }, where funcB has noGasMetering as well.
        // funcA will have `gasStartedOff` as false, funcB will have it as true,
        // so we only turn metering back on at the end of the funcA
        bool gasStartedOff = gasMeteringOff;
        gasMeteringOff = true;

        _;

        // if gas metering was on when this modifier was called, turn it back on at the end
        if (!gasStartedOff) {
            gasMeteringOff = false;
            vm.resumeGasMetering();
        }
    }

    // We use this complex approach of `_viewChainId` and `_pureChainId` to ensure there are no
    // compiler warnings when accessing chain ID in any solidity version supported by forge-std. We
    // can't simply access the chain ID in a normal view or pure function because the solc View Pure
    // Checker changed `chainid` from pure to view in 0.8.0.
    function _viewChainId() private view returns (uint256 chainId) {
        // Assembly required since `block.chainid` was introduced in 0.8.0.
        assembly {
            chainId := chainid()
        }

        address(this); // Silence warnings in older Solc versions.
    }

    function _pureChainId() private pure returns (uint256 chainId) {
        function() internal view returns (uint256) fnIn = _viewChainId;
        function() internal pure returns (uint256) pureChainId;
        assembly {
            pureChainId := fnIn
        }
        chainId = pureChainId();
    }
}

// Wrappers around cheatcodes to avoid footguns
abstract contract StdCheats is StdCheatsSafe {
    using stdStorage for StdStorage;

    StdStorage private stdstore;
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    // Skip forward or rewind time by the specified number of seconds
    function skip(uint256 time) internal virtual {
        vm.warp(block.timestamp + time);
    }

    function rewind(uint256 time) internal virtual {
        vm.warp(block.timestamp - time);
    }

    // Setup a prank from an address that has some ether
    function hoax(address msgSender) internal virtual {
        vm.deal(msgSender, 1 << 128);
        vm.prank(msgSender);
    }

    function hoax(address msgSender, uint256 give) internal virtual {
        vm.deal(msgSender, give);
        vm.prank(msgSender);
    }

    function hoax(address msgSender, address origin) internal virtual {
        vm.deal(msgSender, 1 << 128);
        vm.prank(msgSender, origin);
    }

    function hoax(address msgSender, address origin, uint256 give) internal virtual {
        vm.deal(msgSender, give);
        vm.prank(msgSender, origin);
    }

    // Start perpetual prank from an address that has some ether
    function startHoax(address msgSender) internal virtual {
        vm.deal(msgSender, 1 << 128);
        vm.startPrank(msgSender);
    }

    function startHoax(address msgSender, uint256 give) internal virtual {
        vm.deal(msgSender, give);
        vm.startPrank(msgSender);
    }

    // Start perpetual prank from an address that has some ether
    // tx.origin is set to the origin parameter
    function startHoax(address msgSender, address origin) internal virtual {
        vm.deal(msgSender, 1 << 128);
        vm.startPrank(msgSender, origin);
    }

    function startHoax(address msgSender, address origin, uint256 give) internal virtual {
        vm.deal(msgSender, give);
        vm.startPrank(msgSender, origin);
    }

    function changePrank(address msgSender) internal virtual {
        vm.stopPrank();
        vm.startPrank(msgSender);
    }

    function changePrank(address msgSender, address txOrigin) internal virtual {
        vm.stopPrank();
        vm.startPrank(msgSender, txOrigin);
    }

    // The same as Vm's `deal`
    // Use the alternative signature for ERC20 tokens
    function deal(address to, uint256 give) internal virtual {
        vm.deal(to, give);
    }

    // Set the balance of an account for any ERC20 token
    // Use the alternative signature to update `totalSupply`
    function deal(address token, address to, uint256 give) internal virtual {
        deal(token, to, give, false);
    }

    // Set the balance of an account for any ERC1155 token
    // Use the alternative signature to update `totalSupply`
    function dealERC1155(address token, address to, uint256 id, uint256 give) internal virtual {
        dealERC1155(token, to, id, give, false);
    }

    function deal(address token, address to, uint256 give, bool adjust) internal virtual {
        // get current balance
        (, bytes memory balData) = token.staticcall(abi.encodeWithSelector(0x70a08231, to));
        uint256 prevBal = abi.decode(balData, (uint256));

        // update balance
        stdstore.target(token).sig(0x70a08231).with_key(to).checked_write(give);

        // update total supply
        if (adjust) {
            (, bytes memory totSupData) = token.staticcall(abi.encodeWithSelector(0x18160ddd));
            uint256 totSup = abi.decode(totSupData, (uint256));
            if (give < prevBal) {
                totSup -= (prevBal - give);
            } else {
                totSup += (give - prevBal);
            }
            stdstore.target(token).sig(0x18160ddd).checked_write(totSup);
        }
    }

    function dealERC1155(address token, address to, uint256 id, uint256 give, bool adjust) internal virtual {
        // get current balance
        (, bytes memory balData) = token.staticcall(abi.encodeWithSelector(0x00fdd58e, to, id));
        uint256 prevBal = abi.decode(balData, (uint256));

        // update balance
        stdstore.target(token).sig(0x00fdd58e).with_key(to).with_key(id).checked_write(give);

        // update total supply
        if (adjust) {
            (, bytes memory totSupData) = token.staticcall(abi.encodeWithSelector(0xbd85b039, id));
            require(
                totSupData.length != 0,
                "StdCheats deal(address,address,uint,uint,bool): target contract is not ERC1155Supply."
            );
            uint256 totSup = abi.decode(totSupData, (uint256));
            if (give < prevBal) {
                totSup -= (prevBal - give);
            } else {
                totSup += (give - prevBal);
            }
            stdstore.target(token).sig(0xbd85b039).with_key(id).checked_write(totSup);
        }
    }

    function dealERC721(address token, address to, uint256 id) internal virtual {
        // check if token id is already minted and the actual owner.
        (bool successMinted, bytes memory ownerData) = token.staticcall(abi.encodeWithSelector(0x6352211e, id));
        require(successMinted, "StdCheats deal(address,address,uint,bool): id not minted.");

        // get owner current balance
        (, bytes memory fromBalData) =
            token.staticcall(abi.encodeWithSelector(0x70a08231, abi.decode(ownerData, (address))));
        uint256 fromPrevBal = abi.decode(fromBalData, (uint256));

        // get new user current balance
        (, bytes memory toBalData) = token.staticcall(abi.encodeWithSelector(0x70a08231, to));
        uint256 toPrevBal = abi.decode(toBalData, (uint256));

        // update balances
        stdstore.target(token).sig(0x70a08231).with_key(abi.decode(ownerData, (address))).checked_write(--fromPrevBal);
        stdstore.target(token).sig(0x70a08231).with_key(to).checked_write(++toPrevBal);

        // update owner
        stdstore.target(token).sig(0x6352211e).with_key(id).checked_write(to);
    }

    function deployCodeTo(string memory what, address where) internal virtual {
        deployCodeTo(what, "", 0, where);
    }

    function deployCodeTo(string memory what, bytes memory args, address where) internal virtual {
        deployCodeTo(what, args, 0, where);
    }

    function deployCodeTo(string memory what, bytes memory args, uint256 value, address where) internal virtual {
        bytes memory creationCode = vm.getCode(what);
        vm.etch(where, abi.encodePacked(creationCode, args));
        (bool success, bytes memory runtimeBytecode) = where.call{value: value}("");
        require(success, "StdCheats deployCodeTo(string,bytes,uint256,address): Failed to create runtime bytecode.");
        vm.etch(where, runtimeBytecode);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

pragma experimental ABIEncoderV2;

import {VmSafe} from "./Vm.sol";

// Helpers for parsing and writing JSON files
// To parse:
// ```
// using stdJson for string;
// string memory json = vm.readFile("some_peth");
// json.parseUint("<json_path>");
// ```
// To write:
// ```
// using stdJson for string;
// string memory json = "deploymentArtifact";
// Contract contract = new Contract();
// json.serialize("contractAddress", address(contract));
// json = json.serialize("deploymentTimes", uint(1));
// // store the stringified JSON to the 'json' variable we have been using as a key
// // as we won't need it any longer
// string memory json2 = "finalArtifact";
// string memory final = json2.serialize("depArtifact", json);
// final.write("<some_path>");
// ```

library stdJson {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function parseRaw(string memory json, string memory key) internal pure returns (bytes memory) {
        return vm.parseJson(json, key);
    }

    function readUint(string memory json, string memory key) internal returns (uint256) {
        return vm.parseJsonUint(json, key);
    }

    function readUintArray(string memory json, string memory key) internal returns (uint256[] memory) {
        return vm.parseJsonUintArray(json, key);
    }

    function readInt(string memory json, string memory key) internal returns (int256) {
        return vm.parseJsonInt(json, key);
    }

    function readIntArray(string memory json, string memory key) internal returns (int256[] memory) {
        return vm.parseJsonIntArray(json, key);
    }

    function readBytes32(string memory json, string memory key) internal returns (bytes32) {
        return vm.parseJsonBytes32(json, key);
    }

    function readBytes32Array(string memory json, string memory key) internal returns (bytes32[] memory) {
        return vm.parseJsonBytes32Array(json, key);
    }

    function readString(string memory json, string memory key) internal returns (string memory) {
        return vm.parseJsonString(json, key);
    }

    function readStringArray(string memory json, string memory key) internal returns (string[] memory) {
        return vm.parseJsonStringArray(json, key);
    }

    function readAddress(string memory json, string memory key) internal returns (address) {
        return vm.parseJsonAddress(json, key);
    }

    function readAddressArray(string memory json, string memory key) internal returns (address[] memory) {
        return vm.parseJsonAddressArray(json, key);
    }

    function readBool(string memory json, string memory key) internal returns (bool) {
        return vm.parseJsonBool(json, key);
    }

    function readBoolArray(string memory json, string memory key) internal returns (bool[] memory) {
        return vm.parseJsonBoolArray(json, key);
    }

    function readBytes(string memory json, string memory key) internal returns (bytes memory) {
        return vm.parseJsonBytes(json, key);
    }

    function readBytesArray(string memory json, string memory key) internal returns (bytes[] memory) {
        return vm.parseJsonBytesArray(json, key);
    }

    function serialize(string memory jsonKey, string memory key, bool value) internal returns (string memory) {
        return vm.serializeBool(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bool[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBool(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, uint256 value) internal returns (string memory) {
        return vm.serializeUint(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, uint256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeUint(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, int256 value) internal returns (string memory) {
        return vm.serializeInt(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, int256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeInt(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, address value) internal returns (string memory) {
        return vm.serializeAddress(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, address[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeAddress(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes32 value) internal returns (string memory) {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes32[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes memory value) internal returns (string memory) {
        return vm.serializeBytes(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, string memory value)
        internal
        returns (string memory)
    {
        return vm.serializeString(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, string[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeString(jsonKey, key, value);
    }

    function write(string memory jsonKey, string memory path) internal {
        vm.writeJson(jsonKey, path);
    }

    function write(string memory jsonKey, string memory path, string memory valueKey) internal {
        vm.writeJson(jsonKey, path, valueKey);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

library stdMath {
    int256 private constant INT256_MIN = -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function abs(int256 a) internal pure returns (uint256) {
        // Required or it will fail when `a = type(int256).min`
        if (a == INT256_MIN) {
            return 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        }

        return uint256(a > 0 ? a : -a);
    }

    function delta(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function delta(int256 a, int256 b) internal pure returns (uint256) {
        // a and b are of the same sign
        // this works thanks to two's complement, the left-most bit is the sign bit
        if ((a ^ b) > -1) {
            return delta(abs(a), abs(b));
        }

        // a and b are of opposite signs
        return abs(a) + abs(b);
    }

    function percentDelta(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);

        return absDelta * 1e18 / b;
    }

    function percentDelta(int256 a, int256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);
        uint256 absB = abs(b);

        return absDelta * 1e18 / absB;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {Vm} from "./Vm.sol";

struct StdStorage {
    mapping(address => mapping(bytes4 => mapping(bytes32 => uint256))) slots;
    mapping(address => mapping(bytes4 => mapping(bytes32 => bool))) finds;
    bytes32[] _keys;
    bytes4 _sig;
    uint256 _depth;
    address _target;
    bytes32 _set;
}

library stdStorageSafe {
    event SlotFound(address who, bytes4 fsig, bytes32 keysHash, uint256 slot);
    event WARNING_UninitedSlot(address who, uint256 slot);

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function sigs(string memory sigStr) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sigStr)));
    }

    /// @notice find an arbitrary storage slot given a function sig, input data, address of the contract and a value to check against
    // slot complexity:
    //  if flat, will be bytes32(uint256(uint));
    //  if map, will be keccak256(abi.encode(key, uint(slot)));
    //  if deep map, will be keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))));
    //  if map struct, will be bytes32(uint256(keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))))) + structFieldDepth);
    function find(StdStorage storage self) internal returns (uint256) {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        // calldata to test against
        if (self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
        }
        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        vm.record();
        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32 * field_depth);
        }

        (bytes32[] memory reads,) = vm.accesses(address(who));
        if (reads.length == 1) {
            bytes32 curr = vm.load(who, reads[0]);
            if (curr == bytes32(0)) {
                emit WARNING_UninitedSlot(who, uint256(reads[0]));
            }
            if (fdat != curr) {
                require(
                    false,
                    "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported."
                );
            }
            emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[0]));
            self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[0]);
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
        } else if (reads.length > 1) {
            for (uint256 i = 0; i < reads.length; i++) {
                bytes32 prev = vm.load(who, reads[i]);
                if (prev == bytes32(0)) {
                    emit WARNING_UninitedSlot(who, uint256(reads[i]));
                }
                // store
                vm.store(who, reads[i], bytes32(hex"1337"));
                bool success;
                bytes memory rdat;
                {
                    (success, rdat) = who.staticcall(cald);
                    fdat = bytesToBytes32(rdat, 32 * field_depth);
                }

                if (success && fdat == bytes32(hex"1337")) {
                    // we found which of the slots is the actual one
                    emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[i]));
                    self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[i]);
                    self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
                    vm.store(who, reads[i], prev);
                    break;
                }
                vm.store(who, reads[i], prev);
            }
        } else {
            revert("stdStorage find(StdStorage): No storage use detected for target.");
        }

        require(
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))],
            "stdStorage find(StdStorage): Slot(s) not found."
        );

        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;

        return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        self._target = _target;
        return self;
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        self._sig = _sig;
        return self;
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        self._sig = sigs(_sig);
        return self;
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        self._keys.push(bytes32(uint256(uint160(who))));
        return self;
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        self._keys.push(bytes32(amt));
        return self;
    }

    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        self._keys.push(key);
        return self;
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        self._depth = _depth;
        return self;
    }

    function read(StdStorage storage self) private returns (bytes memory) {
        address t = self._target;
        uint256 s = find(self);
        return abi.encode(vm.load(t, bytes32(s)));
    }

    function read_bytes32(StdStorage storage self) internal returns (bytes32) {
        return abi.decode(read(self), (bytes32));
    }

    function read_bool(StdStorage storage self) internal returns (bool) {
        int256 v = read_int(self);
        if (v == 0) return false;
        if (v == 1) return true;
        revert("stdStorage read_bool(StdStorage): Cannot decode. Make sure you are reading a bool.");
    }

    function read_address(StdStorage storage self) internal returns (address) {
        return abi.decode(read(self), (address));
    }

    function read_uint(StdStorage storage self) internal returns (uint256) {
        return abi.decode(read(self), (uint256));
    }

    function read_int(StdStorage storage self) internal returns (int256) {
        return abi.decode(read(self), (int256));
    }

    function bytesToBytes32(bytes memory b, uint256 offset) private pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint256 i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function flatten(bytes32[] memory b) private pure returns (bytes memory) {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

library stdStorage {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function sigs(string memory sigStr) internal pure returns (bytes4) {
        return stdStorageSafe.sigs(sigStr);
    }

    function find(StdStorage storage self) internal returns (uint256) {
        return stdStorageSafe.find(self);
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        return stdStorageSafe.target(self, _target);
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        return stdStorageSafe.sig(self, _sig);
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        return stdStorageSafe.sig(self, _sig);
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, who);
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, amt);
    }

    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, key);
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        return stdStorageSafe.depth(self, _depth);
    }

    function checked_write(StdStorage storage self, address who) internal {
        checked_write(self, bytes32(uint256(uint160(who))));
    }

    function checked_write(StdStorage storage self, uint256 amt) internal {
        checked_write(self, bytes32(amt));
    }

    function checked_write_int(StdStorage storage self, int256 val) internal {
        checked_write(self, bytes32(uint256(val)));
    }

    function checked_write(StdStorage storage self, bool write) internal {
        bytes32 t;
        /// @solidity memory-safe-assembly
        assembly {
            t := write
        }
        checked_write(self, t);
    }

    function checked_write(StdStorage storage self, bytes32 set) internal {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        if (!self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            find(self);
        }
        bytes32 slot = bytes32(self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]);

        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32 * field_depth);
        }
        bytes32 curr = vm.load(who, slot);

        if (fdat != curr) {
            require(
                false,
                "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported."
            );
        }
        vm.store(who, slot, set);
        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;
    }

    function read_bytes32(StdStorage storage self) internal returns (bytes32) {
        return stdStorageSafe.read_bytes32(self);
    }

    function read_bool(StdStorage storage self) internal returns (bool) {
        return stdStorageSafe.read_bool(self);
    }

    function read_address(StdStorage storage self) internal returns (address) {
        return stdStorageSafe.read_address(self);
    }

    function read_uint(StdStorage storage self) internal returns (uint256) {
        return stdStorageSafe.read_uint(self);
    }

    function read_int(StdStorage storage self) internal returns (int256) {
        return stdStorageSafe.read_int(self);
    }

    // Private function so needs to be copied over
    function bytesToBytes32(bytes memory b, uint256 offset) private pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint256 i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    // Private function so needs to be copied over
    function flatten(bytes32[] memory b) private pure returns (bytes memory) {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {VmSafe} from "./Vm.sol";

library StdStyle {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    string constant RED = "\u001b[91m";
    string constant GREEN = "\u001b[92m";
    string constant YELLOW = "\u001b[93m";
    string constant BLUE = "\u001b[94m";
    string constant MAGENTA = "\u001b[95m";
    string constant CYAN = "\u001b[96m";
    string constant BOLD = "\u001b[1m";
    string constant DIM = "\u001b[2m";
    string constant ITALIC = "\u001b[3m";
    string constant UNDERLINE = "\u001b[4m";
    string constant INVERSE = "\u001b[7m";
    string constant RESET = "\u001b[0m";

    function styleConcat(string memory style, string memory self) private pure returns (string memory) {
        return string(abi.encodePacked(style, self, RESET));
    }

    function red(string memory self) internal pure returns (string memory) {
        return styleConcat(RED, self);
    }

    function red(uint256 self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function red(int256 self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function red(address self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function red(bool self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function redBytes(bytes memory self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function redBytes32(bytes32 self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function green(string memory self) internal pure returns (string memory) {
        return styleConcat(GREEN, self);
    }

    function green(uint256 self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function green(int256 self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function green(address self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function green(bool self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function greenBytes(bytes memory self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function greenBytes32(bytes32 self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function yellow(string memory self) internal pure returns (string memory) {
        return styleConcat(YELLOW, self);
    }

    function yellow(uint256 self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function yellow(int256 self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function yellow(address self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function yellow(bool self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function yellowBytes(bytes memory self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function yellowBytes32(bytes32 self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function blue(string memory self) internal pure returns (string memory) {
        return styleConcat(BLUE, self);
    }

    function blue(uint256 self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function blue(int256 self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function blue(address self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function blue(bool self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function blueBytes(bytes memory self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function blueBytes32(bytes32 self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function magenta(string memory self) internal pure returns (string memory) {
        return styleConcat(MAGENTA, self);
    }

    function magenta(uint256 self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function magenta(int256 self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function magenta(address self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function magenta(bool self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function magentaBytes(bytes memory self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function magentaBytes32(bytes32 self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function cyan(string memory self) internal pure returns (string memory) {
        return styleConcat(CYAN, self);
    }

    function cyan(uint256 self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function cyan(int256 self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function cyan(address self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function cyan(bool self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function cyanBytes(bytes memory self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function cyanBytes32(bytes32 self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function bold(string memory self) internal pure returns (string memory) {
        return styleConcat(BOLD, self);
    }

    function bold(uint256 self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function bold(int256 self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function bold(address self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function bold(bool self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function boldBytes(bytes memory self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function boldBytes32(bytes32 self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function dim(string memory self) internal pure returns (string memory) {
        return styleConcat(DIM, self);
    }

    function dim(uint256 self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function dim(int256 self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function dim(address self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function dim(bool self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function dimBytes(bytes memory self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function dimBytes32(bytes32 self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function italic(string memory self) internal pure returns (string memory) {
        return styleConcat(ITALIC, self);
    }

    function italic(uint256 self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function italic(int256 self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function italic(address self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function italic(bool self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function italicBytes(bytes memory self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function italicBytes32(bytes32 self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function underline(string memory self) internal pure returns (string memory) {
        return styleConcat(UNDERLINE, self);
    }

    function underline(uint256 self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function underline(int256 self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function underline(address self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function underline(bool self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function underlineBytes(bytes memory self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function underlineBytes32(bytes32 self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function inverse(string memory self) internal pure returns (string memory) {
        return styleConcat(INVERSE, self);
    }

    function inverse(uint256 self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    function inverse(int256 self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    function inverse(address self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    function inverse(bool self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    function inverseBytes(bytes memory self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    function inverseBytes32(bytes32 self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

import {IMulticall3} from "./interfaces/IMulticall3.sol";
import {VmSafe} from "./Vm.sol";

abstract contract StdUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    IMulticall3 private constant multicall = IMulticall3(0xcA11bde05977b3631167028862bE2a173976CA11);
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant CONSOLE2_ADDRESS = 0x000000000000000000636F6e736F6c652e6c6f67;
    uint256 private constant INT256_MIN_ABS =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;
    uint256 private constant SECP256K1_ORDER =
        115792089237316195423570985008687907852837564279074904382605163141518161494337;
    uint256 private constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // Used by default when deploying with create2, https://github.com/Arachnid/deterministic-deployment-proxy.
    address private constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    /*//////////////////////////////////////////////////////////////////////////
                                 INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _bound(uint256 x, uint256 min, uint256 max) internal pure virtual returns (uint256 result) {
        require(min <= max, "StdUtils bound(uint256,uint256,uint256): Max is less than min.");
        // If x is between min and max, return x directly. This is to ensure that dictionary values
        // do not get shifted if the min is nonzero. More info: https://github.com/foundry-rs/forge-std/issues/188
        if (x >= min && x <= max) return x;

        uint256 size = max - min + 1;

        // If the value is 0, 1, 2, 3, wrap that to min, min+1, min+2, min+3. Similarly for the UINT256_MAX side.
        // This helps ensure coverage of the min/max values.
        if (x <= 3 && size > x) return min + x;
        if (x >= UINT256_MAX - 3 && size > UINT256_MAX - x) return max - (UINT256_MAX - x);

        // Otherwise, wrap x into the range [min, max], i.e. the range is inclusive.
        if (x > max) {
            uint256 diff = x - max;
            uint256 rem = diff % size;
            if (rem == 0) return max;
            result = min + rem - 1;
        } else if (x < min) {
            uint256 diff = min - x;
            uint256 rem = diff % size;
            if (rem == 0) return min;
            result = max - rem + 1;
        }
    }

    function bound(uint256 x, uint256 min, uint256 max) internal view virtual returns (uint256 result) {
        result = _bound(x, min, max);
        console2_log("Bound Result", result);
    }

    function _bound(int256 x, int256 min, int256 max) internal pure virtual returns (int256 result) {
        require(min <= max, "StdUtils bound(int256,int256,int256): Max is less than min.");

        // Shifting all int256 values to uint256 to use _bound function. The range of two types are:
        // int256 : -(2**255) ~ (2**255 - 1)
        // uint256:     0     ~ (2**256 - 1)
        // So, add 2**255, INT256_MIN_ABS to the integer values.
        //
        // If the given integer value is -2**255, we cannot use `-uint256(-x)` because of the overflow.
        // So, use `~uint256(x) + 1` instead.
        uint256 _x = x < 0 ? (INT256_MIN_ABS - ~uint256(x) - 1) : (uint256(x) + INT256_MIN_ABS);
        uint256 _min = min < 0 ? (INT256_MIN_ABS - ~uint256(min) - 1) : (uint256(min) + INT256_MIN_ABS);
        uint256 _max = max < 0 ? (INT256_MIN_ABS - ~uint256(max) - 1) : (uint256(max) + INT256_MIN_ABS);

        uint256 y = _bound(_x, _min, _max);

        // To move it back to int256 value, subtract INT256_MIN_ABS at here.
        result = y < INT256_MIN_ABS ? int256(~(INT256_MIN_ABS - y) + 1) : int256(y - INT256_MIN_ABS);
    }

    function bound(int256 x, int256 min, int256 max) internal view virtual returns (int256 result) {
        result = _bound(x, min, max);
        console2_log("Bound result", vm.toString(result));
    }

    function boundPrivateKey(uint256 privateKey) internal pure virtual returns (uint256 result) {
        result = _bound(privateKey, 1, SECP256K1_ORDER - 1);
    }

    function bytesToUint(bytes memory b) internal pure virtual returns (uint256) {
        require(b.length <= 32, "StdUtils bytesToUint(bytes): Bytes length exceeds 32.");
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }

    /// @dev Compute the address a contract will be deployed at for a given deployer address and nonce
    /// @notice adapted from Solmate implementation (https://github.com/Rari-Capital/solmate/blob/main/src/utils/LibRLP.sol)
    function computeCreateAddress(address deployer, uint256 nonce) internal pure virtual returns (address) {
        // forgefmt: disable-start
        // The integer zero is treated as an empty byte string, and as a result it only has a length prefix, 0x80, computed via 0x80 + 0.
        // A one byte integer uses its own value as its length prefix, there is no additional "0x80 + length" prefix that comes before it.
        if (nonce == 0x00)      return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))));
        if (nonce <= 0x7f)      return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))));

        // Nonces greater than 1 byte all follow a consistent encoding scheme, where each value is preceded by a prefix of 0x80 + length.
        if (nonce <= 2**8 - 1)  return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), uint8(nonce))));
        if (nonce <= 2**16 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployer, bytes1(0x82), uint16(nonce))));
        if (nonce <= 2**24 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployer, bytes1(0x83), uint24(nonce))));
        // forgefmt: disable-end

        // More details about RLP encoding can be found here: https://eth.wiki/fundamentals/rlp
        // 0xda = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x84 ++ nonce)
        // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
        // 0x84 = 0x80 + 0x04 (0x04 = the bytes length of the nonce, 4 bytes, in hex)
        // We assume nobody can have a nonce large enough to require more than 32 bytes.
        return addressFromLast20Bytes(
            keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), deployer, bytes1(0x84), uint32(nonce)))
        );
    }

    function computeCreate2Address(bytes32 salt, bytes32 initcodeHash, address deployer)
        internal
        pure
        virtual
        returns (address)
    {
        return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, initcodeHash)));
    }

    /// @dev returns the address of a contract created with CREATE2 using the default CREATE2 deployer
    function computeCreate2Address(bytes32 salt, bytes32 initCodeHash) internal pure returns (address) {
        return computeCreate2Address(salt, initCodeHash, CREATE2_FACTORY);
    }

    /// @dev returns the hash of the init code (creation code + no args) used in CREATE2 with no constructor arguments
    /// @param creationCode the creation code of a contract C, as returned by type(C).creationCode
    function hashInitCode(bytes memory creationCode) internal pure returns (bytes32) {
        return hashInitCode(creationCode, "");
    }

    /// @dev returns the hash of the init code (creation code + ABI-encoded args) used in CREATE2
    /// @param creationCode the creation code of a contract C, as returned by type(C).creationCode
    /// @param args the ABI-encoded arguments to the constructor of C
    function hashInitCode(bytes memory creationCode, bytes memory args) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(creationCode, args));
    }

    // Performs a single call with Multicall3 to query the ERC-20 token balances of the given addresses.
    function getTokenBalances(address token, address[] memory addresses)
        internal
        virtual
        returns (uint256[] memory balances)
    {
        uint256 tokenCodeSize;
        assembly {
            tokenCodeSize := extcodesize(token)
        }
        require(tokenCodeSize > 0, "StdUtils getTokenBalances(address,address[]): Token address is not a contract.");

        // ABI encode the aggregate call to Multicall3.
        uint256 length = addresses.length;
        IMulticall3.Call[] memory calls = new IMulticall3.Call[](length);
        for (uint256 i = 0; i < length; ++i) {
            // 0x70a08231 = bytes4("balanceOf(address)"))
            calls[i] = IMulticall3.Call({target: token, callData: abi.encodeWithSelector(0x70a08231, (addresses[i]))});
        }

        // Make the aggregate call.
        (, bytes[] memory returnData) = multicall.aggregate(calls);

        // ABI decode the return data and return the balances.
        balances = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            balances[i] = abi.decode(returnData[i], (uint256));
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function addressFromLast20Bytes(bytes32 bytesValue) private pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    // Used to prevent the compilation of console, which shortens the compilation time when console is not used elsewhere.

    function console2_log(string memory p0, uint256 p1) private view {
        (bool status,) = address(CONSOLE2_ADDRESS).staticcall(abi.encodeWithSignature("log(string,uint256)", p0, p1));
        status;
    }

    function console2_log(string memory p0, string memory p1) private view {
        (bool status,) = address(CONSOLE2_ADDRESS).staticcall(abi.encodeWithSignature("log(string,string)", p0, p1));
        status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

// Cheatcodes are marked as view/pure/none using the following rules:
// 0. A call's observable behaviour includes its return value, logs, reverts and state writes,
// 1. If you can influence a later call's observable behaviour, you're neither `view` nor `pure (you are modifying some state be it the EVM, interpreter, filesystem, etc),
// 2. Otherwise if you can be influenced by an earlier call, or if reading some state, you're `view`,
// 3. Otherwise you're `pure`.

interface VmSafe {
    enum CallerMode {
        None,
        Broadcast,
        RecurrentBroadcast,
        Prank,
        RecurrentPrank
    }

    struct Log {
        bytes32[] topics;
        bytes data;
        address emitter;
    }

    struct Rpc {
        string key;
        string url;
    }

    struct DirEntry {
        string errorMessage;
        string path;
        uint64 depth;
        bool isDir;
        bool isSymlink;
    }

    struct FsMetadata {
        bool isDir;
        bool isSymlink;
        uint256 length;
        bool readOnly;
        uint256 modified;
        uint256 accessed;
        uint256 created;
    }

    // Loads a storage slot from an address
    function load(address target, bytes32 slot) external view returns (bytes32 data);
    // Signs data
    function sign(uint256 privateKey, bytes32 digest) external pure returns (uint8 v, bytes32 r, bytes32 s);
    // Gets the address for a given private key
    function addr(uint256 privateKey) external pure returns (address keyAddr);
    // Gets the nonce of an account
    function getNonce(address account) external view returns (uint64 nonce);
    // Performs a foreign function call via the terminal
    function ffi(string[] calldata commandInput) external returns (bytes memory result);
    // Sets environment variables
    function setEnv(string calldata name, string calldata value) external;
    // Reads environment variables, (name) => (value)
    function envBool(string calldata name) external view returns (bool value);
    function envUint(string calldata name) external view returns (uint256 value);
    function envInt(string calldata name) external view returns (int256 value);
    function envAddress(string calldata name) external view returns (address value);
    function envBytes32(string calldata name) external view returns (bytes32 value);
    function envString(string calldata name) external view returns (string memory value);
    function envBytes(string calldata name) external view returns (bytes memory value);
    // Reads environment variables as arrays
    function envBool(string calldata name, string calldata delim) external view returns (bool[] memory value);
    function envUint(string calldata name, string calldata delim) external view returns (uint256[] memory value);
    function envInt(string calldata name, string calldata delim) external view returns (int256[] memory value);
    function envAddress(string calldata name, string calldata delim) external view returns (address[] memory value);
    function envBytes32(string calldata name, string calldata delim) external view returns (bytes32[] memory value);
    function envString(string calldata name, string calldata delim) external view returns (string[] memory value);
    function envBytes(string calldata name, string calldata delim) external view returns (bytes[] memory value);
    // Read environment variables with default value
    function envOr(string calldata name, bool defaultValue) external returns (bool value);
    function envOr(string calldata name, uint256 defaultValue) external returns (uint256 value);
    function envOr(string calldata name, int256 defaultValue) external returns (int256 value);
    function envOr(string calldata name, address defaultValue) external returns (address value);
    function envOr(string calldata name, bytes32 defaultValue) external returns (bytes32 value);
    function envOr(string calldata name, string calldata defaultValue) external returns (string memory value);
    function envOr(string calldata name, bytes calldata defaultValue) external returns (bytes memory value);
    // Read environment variables as arrays with default value
    function envOr(string calldata name, string calldata delim, bool[] calldata defaultValue)
        external
        returns (bool[] memory value);
    function envOr(string calldata name, string calldata delim, uint256[] calldata defaultValue)
        external
        returns (uint256[] memory value);
    function envOr(string calldata name, string calldata delim, int256[] calldata defaultValue)
        external
        returns (int256[] memory value);
    function envOr(string calldata name, string calldata delim, address[] calldata defaultValue)
        external
        returns (address[] memory value);
    function envOr(string calldata name, string calldata delim, bytes32[] calldata defaultValue)
        external
        returns (bytes32[] memory value);
    function envOr(string calldata name, string calldata delim, string[] calldata defaultValue)
        external
        returns (string[] memory value);
    function envOr(string calldata name, string calldata delim, bytes[] calldata defaultValue)
        external
        returns (bytes[] memory value);
    // Records all storage reads and writes
    function record() external;
    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address target) external returns (bytes32[] memory readSlots, bytes32[] memory writeSlots);
    // Gets the _creation_ bytecode from an artifact file. Takes in the relative path to the json file
    function getCode(string calldata artifactPath) external view returns (bytes memory creationBytecode);
    // Gets the _deployed_ bytecode from an artifact file. Takes in the relative path to the json file
    function getDeployedCode(string calldata artifactPath) external view returns (bytes memory runtimeBytecode);
    // Labels an address in call traces
    function label(address account, string calldata newLabel) external;
    // Gets the label for the specified address
    function getLabel(address account) external returns (string memory currentLabel);
    // Using the address that calls the test contract, has the next call (at this call depth only) create a transaction that can later be signed and sent onchain
    function broadcast() external;
    // Has the next call (at this call depth only) create a transaction with the address provided as the sender that can later be signed and sent onchain
    function broadcast(address signer) external;
    // Has the next call (at this call depth only) create a transaction with the private key provided as the sender that can later be signed and sent onchain
    function broadcast(uint256 privateKey) external;
    // Using the address that calls the test contract, has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast() external;
    // Has all subsequent calls (at this call depth only) create transactions with the address provided that can later be signed and sent onchain
    function startBroadcast(address signer) external;
    // Has all subsequent calls (at this call depth only) create transactions with the private key provided that can later be signed and sent onchain
    function startBroadcast(uint256 privateKey) external;
    // Stops collecting onchain transactions
    function stopBroadcast() external;

    // Get the path of the current project root.
    function projectRoot() external view returns (string memory path);
    // Reads the entire content of file to string. `path` is relative to the project root.
    function readFile(string calldata path) external view returns (string memory data);
    // Reads the entire content of file as binary. `path` is relative to the project root.
    function readFileBinary(string calldata path) external view returns (bytes memory data);
    // Reads next line of file to string.
    function readLine(string calldata path) external view returns (string memory line);
    // Writes data to file, creating a file if it does not exist, and entirely replacing its contents if it does.
    // `path` is relative to the project root.
    function writeFile(string calldata path, string calldata data) external;
    // Writes binary data to a file, creating a file if it does not exist, and entirely replacing its contents if it does.
    // `path` is relative to the project root.
    function writeFileBinary(string calldata path, bytes calldata data) external;
    // Writes line to file, creating a file if it does not exist.
    // `path` is relative to the project root.
    function writeLine(string calldata path, string calldata data) external;
    // Closes file for reading, resetting the offset and allowing to read it from beginning with readLine.
    // `path` is relative to the project root.
    function closeFile(string calldata path) external;
    // Removes a file from the filesystem.
    // This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - `path` points to a directory.
    // - The file doesn't exist.
    // - The user lacks permissions to remove the file.
    // `path` is relative to the project root.
    function removeFile(string calldata path) external;
    // Creates a new, empty directory at the provided path.
    // This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - User lacks permissions to modify `path`.
    // - A parent of the given path doesn't exist and `recursive` is false.
    // - `path` already exists and `recursive` is false.
    // `path` is relative to the project root.
    function createDir(string calldata path, bool recursive) external;
    // Removes a directory at the provided path.
    // This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - `path` doesn't exist.
    // - `path` isn't a directory.
    // - User lacks permissions to modify `path`.
    // - The directory is not empty and `recursive` is false.
    // `path` is relative to the project root.
    function removeDir(string calldata path, bool recursive) external;
    // Reads the directory at the given path recursively, up to `max_depth`.
    // `max_depth` defaults to 1, meaning only the direct children of the given directory will be returned.
    // Follows symbolic links if `follow_links` is true.
    function readDir(string calldata path) external view returns (DirEntry[] memory entries);
    function readDir(string calldata path, uint64 maxDepth) external view returns (DirEntry[] memory entries);
    function readDir(string calldata path, uint64 maxDepth, bool followLinks)
        external
        view
        returns (DirEntry[] memory entries);
    // Reads a symbolic link, returning the path that the link points to.
    // This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - `path` is not a symbolic link.
    // - `path` does not exist.
    function readLink(string calldata linkPath) external view returns (string memory targetPath);
    // Given a path, query the file system to get information about a file, directory, etc.
    function fsMetadata(string calldata path) external view returns (FsMetadata memory metadata);

    // Convert values to a string
    function toString(address value) external pure returns (string memory stringifiedValue);
    function toString(bytes calldata value) external pure returns (string memory stringifiedValue);
    function toString(bytes32 value) external pure returns (string memory stringifiedValue);
    function toString(bool value) external pure returns (string memory stringifiedValue);
    function toString(uint256 value) external pure returns (string memory stringifiedValue);
    function toString(int256 value) external pure returns (string memory stringifiedValue);
    // Convert values from a string
    function parseBytes(string calldata stringifiedValue) external pure returns (bytes memory parsedValue);
    function parseAddress(string calldata stringifiedValue) external pure returns (address parsedValue);
    function parseUint(string calldata stringifiedValue) external pure returns (uint256 parsedValue);
    function parseInt(string calldata stringifiedValue) external pure returns (int256 parsedValue);
    function parseBytes32(string calldata stringifiedValue) external pure returns (bytes32 parsedValue);
    function parseBool(string calldata stringifiedValue) external pure returns (bool parsedValue);
    // Record all the transaction logs
    function recordLogs() external;
    // Gets all the recorded logs
    function getRecordedLogs() external returns (Log[] memory logs);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path m/44'/60'/0'/0/{index}
    function deriveKey(string calldata mnemonic, uint32 index) external pure returns (uint256 privateKey);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at {derivationPath}{index}
    function deriveKey(string calldata mnemonic, string calldata derivationPath, uint32 index)
        external
        pure
        returns (uint256 privateKey);
    // Adds a private key to the local forge wallet and returns the address
    function rememberKey(uint256 privateKey) external returns (address keyAddr);
    //
    // parseJson
    //
    // ----
    // In case the returned value is a JSON object, it's encoded as a ABI-encoded tuple. As JSON objects
    // don't have the notion of ordered, but tuples do, they JSON object is encoded with it's fields ordered in
    // ALPHABETICAL order. That means that in order to successfully decode the tuple, we need to define a tuple that
    // encodes the fields in the same order, which is alphabetical. In the case of Solidity structs, they are encoded
    // as tuples, with the attributes in the order in which they are defined.
    // For example: json = { 'a': 1, 'b': 0xa4tb......3xs}
    // a: uint256
    // b: address
    // To decode that json, we need to define a struct or a tuple as follows:
    // struct json = { uint256 a; address b; }
    // If we defined a json struct with the opposite order, meaning placing the address b first, it would try to
    // decode the tuple in that order, and thus fail.
    // ----
    // Given a string of JSON, return it as ABI-encoded
    function parseJson(string calldata json, string calldata key) external pure returns (bytes memory abiEncodedData);
    function parseJson(string calldata json) external pure returns (bytes memory abiEncodedData);

    // The following parseJson cheatcodes will do type coercion, for the type that they indicate.
    // For example, parseJsonUint will coerce all values to a uint256. That includes stringified numbers '12'
    // and hex numbers '0xEF'.
    // Type coercion works ONLY for discrete values or arrays. That means that the key must return a value or array, not
    // a JSON object.
    function parseJsonUint(string calldata, string calldata) external returns (uint256);
    function parseJsonUintArray(string calldata, string calldata) external returns (uint256[] memory);
    function parseJsonInt(string calldata, string calldata) external returns (int256);
    function parseJsonIntArray(string calldata, string calldata) external returns (int256[] memory);
    function parseJsonBool(string calldata, string calldata) external returns (bool);
    function parseJsonBoolArray(string calldata, string calldata) external returns (bool[] memory);
    function parseJsonAddress(string calldata, string calldata) external returns (address);
    function parseJsonAddressArray(string calldata, string calldata) external returns (address[] memory);
    function parseJsonString(string calldata, string calldata) external returns (string memory);
    function parseJsonStringArray(string calldata, string calldata) external returns (string[] memory);
    function parseJsonBytes(string calldata, string calldata) external returns (bytes memory);
    function parseJsonBytesArray(string calldata, string calldata) external returns (bytes[] memory);
    function parseJsonBytes32(string calldata, string calldata) external returns (bytes32);
    function parseJsonBytes32Array(string calldata, string calldata) external returns (bytes32[] memory);

    // Serialize a key and value to a JSON object stored in-memory that can be later written to a file
    // It returns the stringified version of the specific JSON file up to that moment.
    function serializeBool(string calldata objectKey, string calldata valueKey, bool value)
        external
        returns (string memory json);
    function serializeUint(string calldata objectKey, string calldata valueKey, uint256 value)
        external
        returns (string memory json);
    function serializeInt(string calldata objectKey, string calldata valueKey, int256 value)
        external
        returns (string memory json);
    function serializeAddress(string calldata objectKey, string calldata valueKey, address value)
        external
        returns (string memory json);
    function serializeBytes32(string calldata objectKey, string calldata valueKey, bytes32 value)
        external
        returns (string memory json);
    function serializeString(string calldata objectKey, string calldata valueKey, string calldata value)
        external
        returns (string memory json);
    function serializeBytes(string calldata objectKey, string calldata valueKey, bytes calldata value)
        external
        returns (string memory json);

    function serializeBool(string calldata objectKey, string calldata valueKey, bool[] calldata values)
        external
        returns (string memory json);
    function serializeUint(string calldata objectKey, string calldata valueKey, uint256[] calldata values)
        external
        returns (string memory json);
    function serializeInt(string calldata objectKey, string calldata valueKey, int256[] calldata values)
        external
        returns (string memory json);
    function serializeAddress(string calldata objectKey, string calldata valueKey, address[] calldata values)
        external
        returns (string memory json);
    function serializeBytes32(string calldata objectKey, string calldata valueKey, bytes32[] calldata values)
        external
        returns (string memory json);
    function serializeString(string calldata objectKey, string calldata valueKey, string[] calldata values)
        external
        returns (string memory json);
    function serializeBytes(string calldata objectKey, string calldata valueKey, bytes[] calldata values)
        external
        returns (string memory json);

    //
    // writeJson
    //
    // ----
    // Write a serialized JSON object to a file. If the file exists, it will be overwritten.
    // Let's assume we want to write the following JSON to a file:
    //
    // { "boolean": true, "number": 342, "object": { "title": "finally json serialization" } }
    //
    // ```
    //  string memory json1 = "some key";
    //  vm.serializeBool(json1, "boolean", true);
    //  vm.serializeBool(json1, "number", uint256(342));
    //  json2 = "some other key";
    //  string memory output = vm.serializeString(json2, "title", "finally json serialization");
    //  string memory finalJson = vm.serialize(json1, "object", output);
    //  vm.writeJson(finalJson, "./output/example.json");
    // ```
    // The critical insight is that every invocation of serialization will return the stringified version of the JSON
    // up to that point. That means we can construct arbitrary JSON objects and then use the return stringified version
    // to serialize them as values to another JSON object.
    //
    // json1 and json2 are simply keys used by the backend to keep track of the objects. So vm.serializeJson(json1,..)
    // will find the object in-memory that is keyed by "some key".
    function writeJson(string calldata json, string calldata path) external;
    // Write a serialized JSON object to an **existing** JSON file, replacing a value with key = <value_key>
    // This is useful to replace a specific value of a JSON file, without having to parse the entire thing
    function writeJson(string calldata json, string calldata path, string calldata valueKey) external;
    // Returns the RPC url for the given alias
    function rpcUrl(string calldata rpcAlias) external view returns (string memory json);
    // Returns all rpc urls and their aliases `[alias, url][]`
    function rpcUrls() external view returns (string[2][] memory urls);
    // Returns all rpc urls and their aliases as structs.
    function rpcUrlStructs() external view returns (Rpc[] memory urls);
    // If the condition is false, discard this run's fuzz inputs and generate new ones.
    function assume(bool condition) external pure;
    // Pauses gas metering (i.e. gas usage is not counted). Noop if already paused.
    function pauseGasMetering() external;
    // Resumes gas metering (i.e. gas usage is counted again). Noop if already on.
    function resumeGasMetering() external;
    // Writes a breakpoint to jump to in the debugger
    function breakpoint(string calldata char) external;
    // Writes a conditional breakpoint to jump to in the debugger
    function breakpoint(string calldata char, bool value) external;
}

interface Vm is VmSafe {
    // Sets block.timestamp
    function warp(uint256 newTimestamp) external;
    // Sets block.height
    function roll(uint256 newHeight) external;
    // Sets block.basefee
    function fee(uint256 newBasefee) external;
    // Sets block.difficulty
    // Not available on EVM versions from Paris onwards. Use `prevrandao` instead.
    // If used on unsupported EVM versions it will revert.
    function difficulty(uint256 newDifficulty) external;
    // Sets block.prevrandao
    // Not available on EVM versions before Paris. Use `difficulty` instead.
    // If used on unsupported EVM versions it will revert.
    function prevrandao(bytes32 newPrevrandao) external;
    // Sets block.chainid
    function chainId(uint256 newChainId) external;
    // Sets tx.gasprice
    function txGasPrice(uint256 newGasPrice) external;
    // Stores a value to an address' storage slot.
    function store(address target, bytes32 slot, bytes32 value) external;
    // Sets the nonce of an account; must be higher than the current nonce of the account
    function setNonce(address account, uint64 newNonce) external;
    // Sets the nonce of an account to an arbitrary value
    function setNonceUnsafe(address account, uint64 newNonce) external;
    // Resets the nonce of an account to 0 for EOAs and 1 for contract accounts
    function resetNonce(address account) external;
    // Sets the *next* call's msg.sender to be the input address
    function prank(address msgSender) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address msgSender) external;
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address msgSender, address txOrigin) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address msgSender, address txOrigin) external;
    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
    // Reads the current `msg.sender` and `tx.origin` from state and reports if there is any active caller modification
    function readCallers() external returns (CallerMode callerMode, address msgSender, address txOrigin);
    // Sets an address' balance
    function deal(address account, uint256 newBalance) external;
    // Sets an address' code
    function etch(address target, bytes calldata newRuntimeBytecode) external;
    // Marks a test as skipped. Must be called at the top of the test.
    function skip(bool skipTest) external;
    // Expects an error on next call
    function expectRevert(bytes calldata revertData) external;
    function expectRevert(bytes4 revertData) external;
    function expectRevert() external;

    // Prepare an expected log with all four checks enabled.
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data.
    // Second form also checks supplied address against emitting contract.
    function expectEmit() external;
    function expectEmit(address emitter) external;

    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans).
    // Second form also checks supplied address against emitting contract.
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) external;
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter)
        external;

    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address callee, bytes calldata data, bytes calldata returnData) external;
    // Mocks a call to an address with a specific msg.value, returning specified data.
    // Calldata match takes precedence over msg.value in case of ambiguity.
    function mockCall(address callee, uint256 msgValue, bytes calldata data, bytes calldata returnData) external;
    // Reverts a call to an address with specified revert data.
    function mockCallRevert(address callee, bytes calldata data, bytes calldata revertData) external;
    // Reverts a call to an address with a specific msg.value, with specified revert data.
    function mockCallRevert(address callee, uint256 msgValue, bytes calldata data, bytes calldata revertData)
        external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expects a call to an address with the specified calldata.
    // Calldata can either be a strict or a partial match
    function expectCall(address callee, bytes calldata data) external;
    // Expects given number of calls to an address with the specified calldata.
    function expectCall(address callee, bytes calldata data, uint64 count) external;
    // Expects a call to an address with the specified msg.value and calldata
    function expectCall(address callee, uint256 msgValue, bytes calldata data) external;
    // Expects given number of calls to an address with the specified msg.value and calldata
    function expectCall(address callee, uint256 msgValue, bytes calldata data, uint64 count) external;
    // Expect a call to an address with the specified msg.value, gas, and calldata.
    function expectCall(address callee, uint256 msgValue, uint64 gas, bytes calldata data) external;
    // Expects given number of calls to an address with the specified msg.value, gas, and calldata.
    function expectCall(address callee, uint256 msgValue, uint64 gas, bytes calldata data, uint64 count) external;
    // Expect a call to an address with the specified msg.value and calldata, and a *minimum* amount of gas.
    function expectCallMinGas(address callee, uint256 msgValue, uint64 minGas, bytes calldata data) external;
    // Expect given number of calls to an address with the specified msg.value and calldata, and a *minimum* amount of gas.
    function expectCallMinGas(address callee, uint256 msgValue, uint64 minGas, bytes calldata data, uint64 count)
        external;
    // Only allows memory writes to offsets [0x00, 0x60) ∪ [min, max) in the current subcontext. If any other
    // memory is written to, the test will fail. Can be called multiple times to add more ranges to the set.
    function expectSafeMemory(uint64 min, uint64 max) external;
    // Only allows memory writes to offsets [0x00, 0x60) ∪ [min, max) in the next created subcontext.
    // If any other memory is written to, the test will fail. Can be called multiple times to add more ranges
    // to the set.
    function expectSafeMemoryCall(uint64 min, uint64 max) external;
    // Sets block.coinbase
    function coinbase(address newCoinbase) external;
    // Snapshot the current state of the evm.
    // Returns the id of the snapshot that was created.
    // To revert a snapshot use `revertTo`
    function snapshot() external returns (uint256 snapshotId);
    // Revert the state of the EVM to a previous snapshot
    // Takes the snapshot id to revert to.
    // This deletes the snapshot and all snapshots taken after the given snapshot id.
    function revertTo(uint256 snapshotId) external returns (bool success);
    // Creates a new fork with the given endpoint and block and returns the identifier of the fork
    function createFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256 forkId);
    // Creates a new fork with the given endpoint and the _latest_ block and returns the identifier of the fork
    function createFork(string calldata urlOrAlias) external returns (uint256 forkId);
    // Creates a new fork with the given endpoint and at the block the given transaction was mined in, replays all transaction mined in the block before the transaction,
    // and returns the identifier of the fork
    function createFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256 forkId);
    // Creates _and_ also selects a new fork with the given endpoint and block and returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256 forkId);
    // Creates _and_ also selects new fork with the given endpoint and at the block the given transaction was mined in, replays all transaction mined in the block before
    // the transaction, returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256 forkId);
    // Creates _and_ also selects a new fork with the given endpoint and the latest block and returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias) external returns (uint256 forkId);
    // Takes a fork identifier created by `createFork` and sets the corresponding forked state as active.
    function selectFork(uint256 forkId) external;
    /// Returns the identifier of the currently active fork. Reverts if no fork is currently active.
    function activeFork() external view returns (uint256 forkId);
    // Updates the currently active fork to given block number
    // This is similar to `roll` but for the currently active fork
    function rollFork(uint256 blockNumber) external;
    // Updates the currently active fork to given transaction
    // this will `rollFork` with the number of the block the transaction was mined in and replays all transaction mined before it in the block
    function rollFork(bytes32 txHash) external;
    // Updates the given fork to given block number
    function rollFork(uint256 forkId, uint256 blockNumber) external;
    // Updates the given fork to block number of the given transaction and replays all transaction mined before it in the block
    function rollFork(uint256 forkId, bytes32 txHash) external;
    // Marks that the account(s) should use persistent storage across fork swaps in a multifork setup
    // Meaning, changes made to the state of this account will be kept when switching forks
    function makePersistent(address account) external;
    function makePersistent(address account0, address account1) external;
    function makePersistent(address account0, address account1, address account2) external;
    function makePersistent(address[] calldata accounts) external;
    // Revokes persistent status from the address, previously added via `makePersistent`
    function revokePersistent(address account) external;
    function revokePersistent(address[] calldata accounts) external;
    // Returns true if the account is marked as persistent
    function isPersistent(address account) external view returns (bool persistent);
    // In forking mode, explicitly grant the given address cheatcode access
    function allowCheatcodes(address account) external;
    // Fetches the given transaction from the active fork and executes it on the current state
    function transact(bytes32 txHash) external;
    // Fetches the given transaction from the given fork and executes it on the current state
    function transact(uint256 forkId, bytes32 txHash) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {StdStorage} from "./StdStorage.sol";
import {Vm, VmSafe} from "./Vm.sol";

abstract contract CommonBase {
    // Cheat code address, 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D.
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    // console.sol and console2.sol work by executing a staticcall to this address.
    address internal constant CONSOLE = 0x000000000000000000636F6e736F6c652e6c6f67;
    // Used when deploying with create2, https://github.com/Arachnid/deterministic-deployment-proxy.
    address internal constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    // Default address for tx.origin and msg.sender, 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38.
    address internal constant DEFAULT_SENDER = address(uint160(uint256(keccak256("foundry default caller"))));
    // Address of the test contract, deployed by the DEFAULT_SENDER.
    address internal constant DEFAULT_TEST_CONTRACT = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;
    // Deterministic deployment address of the Multicall3 contract.
    address internal constant MULTICALL3_ADDRESS = 0xcA11bde05977b3631167028862bE2a173976CA11;
    // The order of the secp256k1 curve.
    uint256 internal constant SECP256K1_ORDER =
        115792089237316195423570985008687907852837564279074904382605163141518161494337;

    uint256 internal constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    Vm internal constant vm = Vm(VM_ADDRESS);
    StdStorage internal stdstore;
}

abstract contract TestBase is CommonBase {}

abstract contract ScriptBase is CommonBase {
    VmSafe internal constant vmSafe = VmSafe(VM_ADDRESS);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../external/erc/IERC1271.sol";
import "./IVault.sol";

interface IIntegrationVault is IVault, IERC1271 {
    /// @notice Pushes tokens on the vault balance to the underlying protocol. For example, for Yearn this operation will take USDC from
    /// the contract balance and convert it to yUSDC.
    /// @dev Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Also notice that this operation doesn't guarantee that tokenAmounts will be invested in full.
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function push(
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice The same as `push` method above but transfers tokens to vault balance prior to calling push.
    /// After the `push` it returns all the leftover tokens back (`push` method doesn't guarantee that tokenAmounts will be invested in full).
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function transferAndPush(
        address from,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Pulls tokens from the underlying protocol to the `to` address.
    /// @dev Can only be called but Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    /// When called by vault owner this method just pulls the tokens from the protocol to the `to` address
    /// When called by strategy on vault other than zero vault it pulls the tokens to zero vault (required `to` == zero vault)
    /// When called by strategy on zero vault it pulls the tokens to zero vault, pushes tokens on the `to` vault, and reclaims everything that's left.
    /// Thus any vault other than zero vault cannot have any tokens on it
    ///
    /// Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Pull is fulfilled on the best effort basis, i.e. if the tokenAmounts overflows available funds it withdraws all the funds.
    /// @param to Address to receive the tokens
    /// @param tokens Tokens to pull
    /// @param tokenAmounts Amounts of tokens to pull
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually withdrawn. It could be less than tokenAmounts (but not higher)
    function pull(
        address to,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Claim ERC20 tokens from vault balance to zero vault.
    /// @dev Cannot be called from zero vault.
    /// @param tokens Tokens to claim
    /// @return actualTokenAmounts Amounts reclaimed
    function reclaimTokens(address[] memory tokens) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Execute one of whitelisted calls.
    /// @dev Can only be called by Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    ///
    /// Since this method allows sending arbitrary transactions, the destinations of the calls
    /// are whitelisted by Protocol Governance.
    /// @param to Address of the reward pool
    /// @param selector Selector of the call
    /// @param data Abi encoded parameters to `to::selector`
    /// @return result Result of execution of the call
    function externalCall(
        address to,
        bytes4 selector,
        bytes memory data
    ) external payable returns (bytes memory result);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IPoolInitializer.sol";
import "./IPeripheryPayments.sol";
import "./IPeripheryImmutableState.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Ramses V2 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface IRamsesV2NonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721
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

    /// @notice Emitted when the attachment of an NFP is switched to a different veRam NFT.
    /// @param tokenId The identifier of the NFP for which the attachment is switched.
    /// @param oldVeRamTokenId The identifier of the previous veRam NFT to which the NFP was attached.
    /// @param newVeRamTokenId The identifier of the new veRam NFT to which the NFP was attached.
    event SwitchAttachment(uint256 indexed tokenId, uint256 oldVeRamTokenId, uint256 newVeRamTokenId);

    /// @notice The address of the veRam NFTs
    function veRam() external view returns (address);

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
        // the fee growth of the aggregate position as of the last action on the individual position
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // how many uncollected tokens are owed to the position, as of the last computation
        uint128 tokensOwed0;
        uint128 tokensOwed1;
        // the veRam tokenId attached
        uint256 veRamTokenId;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
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
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

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
pragma solidity ^0.8.0;

import "./pool/IRamsesV2PoolImmutables.sol";
import "./pool/IRamsesV2PoolState.sol";
import "./pool/IRamsesV2PoolDerivedState.sol";
import "./pool/IRamsesV2PoolActions.sol";
import "./pool/IRamsesV2PoolOwnerActions.sol";
import "./pool/IRamsesV2PoolEvents.sol";

/// @title The interface for a Ramses V2 Pool
/// @notice A Ramses pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces

interface IRamsesV2Pool is
    IRamsesV2PoolImmutables,
    IRamsesV2PoolState,
    IRamsesV2PoolDerivedState,
    IRamsesV2PoolActions,
    //IRamsesV2PoolOwnerActions,
    IRamsesV2PoolEvents
{
    /// @notice Initializes a pool with parameters provided
    function initialize(
        address _factory,
        address _nfpManager,
        address _veRam,
        address _voter,
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickSpacing
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Oracle price for tokens as a Q64.96 value.
    /// @notice Returns pricing information based on the indexes of non-zero bits in safetyIndicesSet.
    /// @notice It is possible that not all indices will have their respective prices returned.
    /// @dev The price is token1 / token0 i.e. how many weis of token1 required for 1 wei of token0.
    /// The safety indexes are:
    ///
    /// 1 - unsafe, this is typically a spot price that can be easily manipulated,
    ///
    /// 2 - 4 - more or less safe, this is typically a uniV3 oracle, where the safety is defined by the timespan of the average price
    ///
    /// 5 - safe - this is typically a chailink oracle
    /// @param token0 Reference to token0
    /// @param token1 Reference to token1
    /// @param safetyIndicesSet Bitmask of safety indices that are allowed for the return prices. For set of safety indexes = { 1 }, safetyIndicesSet = 0x2
    /// @return pricesX96 Prices that satisfy safetyIndex and tokens
    /// @return safetyIndices Safety indices for those prices
    function priceX96(
        address token0,
        address token1,
        uint256 safetyIndicesSet
    ) external view returns (uint256[] memory pricesX96, uint256[] memory safetyIndices);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IProtocolGovernance.sol";
import "../IVaultRegistry.sol";
import "./IVault.sol";

interface IVaultGovernance {
    /// @notice Internal references of the contract.
    /// @param protocolGovernance Reference to Protocol Governance
    /// @param registry Reference to Vault Registry
    struct InternalParams {
        IProtocolGovernance protocolGovernance;
        IVaultRegistry registry;
        IVault singleton;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp in unix time seconds after which staged Delayed Strategy Params could be committed.
    /// @param nft Nft of the vault
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params could be committed.
    function delayedProtocolParamsTimestamp() external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params Per Vault could be committed.
    /// @param nft Nft of the vault
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Internal Params could be committed.
    function internalParamsTimestamp() external view returns (uint256);

    /// @notice Internal Params of the contract.
    function internalParams() external view returns (InternalParams memory);

    /// @notice Staged new Internal Params.
    /// @dev The Internal Params could be committed after internalParamsTimestamp
    function stagedInternalParams() external view returns (InternalParams memory);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage new Internal Params.
    /// @param newParams New Internal Params
    function stageInternalParams(InternalParams memory newParams) external;

    /// @notice Commit staged Internal Params.
    function commitInternalParams() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IDefaultAccessControl is IAccessControlEnumerable {
    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is admin, `false` otherwise
    function isAdmin(address who) external view returns (bool);

    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is operator, `false` otherwise
    function isOperator(address who) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

interface IMulticall3 {
    struct Call {
        address target;
        bytes callData;
    }

    struct Call3 {
        address target;
        bool allowFailure;
        bytes callData;
    }

    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function aggregate(Call[] calldata calls)
        external
        payable
        returns (uint256 blockNumber, bytes[] memory returnData);

    function aggregate3(Call3[] calldata calls) external payable returns (Result[] memory returnData);

    function aggregate3Value(Call3Value[] calldata calls) external payable returns (Result[] memory returnData);

    function blockAndAggregate(Call[] calldata calls)
        external
        payable
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);

    function getBasefee() external view returns (uint256 basefee);

    function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash);

    function getBlockNumber() external view returns (uint256 blockNumber);

    function getChainId() external view returns (uint256 chainid);

    function getCurrentBlockCoinbase() external view returns (address coinbase);

    function getCurrentBlockDifficulty() external view returns (uint256 difficulty);

    function getCurrentBlockGasLimit() external view returns (uint256 gaslimit);

    function getCurrentBlockTimestamp() external view returns (uint256 timestamp);

    function getEthBalance(address addr) external view returns (uint256 balance);

    function getLastBlockHash() external view returns (bytes32 blockHash);

    function tryAggregate(bool requireSuccess, Call[] calldata calls)
        external
        payable
        returns (Result[] memory returnData);

    function tryBlockAndAggregate(bool requireSuccess, Call[] calldata calls)
        external
        payable
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1271 {
    /// @notice Verifies offchain signature.
    /// @dev Should return whether the signature provided is valid for the provided hash
    ///
    /// MUST return the bytes4 magic value 0x1626ba7e when function passes.
    ///
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    ///
    /// MUST allow external calls
    /// @param _hash Hash of the data to be signed
    /// @param _signature Signature byte array associated with _hash
    /// @return magicValue 0x1626ba7e if valid, 0xffffffff otherwise
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IVaultGovernance.sol";

interface IVault is IERC165 {
    /// @notice Checks if the vault is initialized

    function initialized() external view returns (bool);

    /// @notice VaultRegistry NFT for this vault
    function nft() external view returns (uint256);

    /// @notice Address of the Vault Governance for this contract.
    function vaultGovernance() external view returns (IVaultGovernance);

    /// @notice ERC20 tokens under Vault management.
    function vaultTokens() external view returns (address[] memory);

    /// @notice Checks if a token is vault token
    /// @param token Address of the token to check
    /// @return `true` if this token is managed by Vault
    function isVaultToken(address token) external view returns (bool);

    /// @notice Total value locked for this contract.
    /// @dev Generally it is the underlying token value of this contract in some
    /// other DeFi protocol. For example, for USDC Yearn Vault this would be total USDC balance that could be withdrawn for Yearn to this contract.
    /// The tvl itself is estimated in some range. Sometimes the range is exact, sometimes it's not
    /// @return minTokenAmounts Lower bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    /// @return maxTokenAmounts Upper bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    function tvl() external view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts);

    /// @notice Existential amounts for each token
    function pullExistentials() external view returns (uint256[] memory);
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
pragma solidity ^0.8.0;
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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IRamsesV2PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IRamsesV2Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The contract that manages RamsesV2 NFPs, which must adhere to the INonfungiblePositionManager interface
    /// @return The contract address
    function nfpManager() external view returns (address);

    /// @notice The contract that manages veRamses NFTs, which must adhere to the IVotinEscrow interface
    /// @return The contract address
    function veRam() external view returns (address);

    /// @notice The contract that manages Ramses votes, which must adhere to the IVoter interface
    /// @return The contract address
    function voter() external view returns (address);

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
pragma solidity ^0.8.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IRamsesV2PoolState {
    /// @notice reads arbitrary storage slots and returns the bytes
    /// @param slots The slots to read from
    /// @return returnData The data read from the slots
    function readStorage(bytes32[] calldata slots) external view returns (bytes32[] memory returnData);

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

    /// @notice Returns the last tick of a given period
    /// @param period The period in question
    /// @return previousPeriod The period before current period
    /// @dev this is because there might be periods without trades
    ///  startTick The start tick of the period
    ///  lastTick The last tick of the period, if the period is finished
    ///  endSecondsPerLiquidityPeriodX128 Seconds per liquidity at period's end
    ///  endSecondsPerBoostedLiquidityPeriodX128 Seconds per boosted liquidity at period's end
    function periods(uint256 period)
        external
        view
        returns (
            uint32 previousPeriod,
            int24 startTick,
            int24 lastTick,
            uint160 endSecondsPerLiquidityCumulativeX128,
            uint160 endSecondsPerBoostedLiquidityCumulativeX128,
            uint32 boostedInRange
        );

    /// @notice The last period where a trade or liquidity change happened
    function lastPeriod() external view returns (uint256);

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

    /// @notice The currently in range derived liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function boostedLiquidity() external view returns (uint128);

    /// @notice Get the boost information for a specific position at a period
    /// @return boostAmount the amount of boost this position has for this period,
    /// veRamAmount the amount of veRam attached to this position for this period,
    /// secondsDebtX96 used to account for changes in the deposit amount during the period
    /// boostedSecondsDebtX96 used to account for changes in the boostAmount and veRam locked during the period,
    function boostInfos(uint256 period, bytes32 key)
        external
        view
        returns (
            uint128 boostAmount,
            int128 veRamAmount,
            int256 secondsDebtX96,
            int256 boostedSecondsDebtX96
        );

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
            uint128 boostedLiquidityGross,
            int128 boostedLiquidityNet,
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
    /// Returns attachedVeRamId the veRam tokenId attached to the position
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1,
            uint256 attachedVeRamId
        );

    /// @notice Returns a period's total boost amount and total veRam attached
    /// @param period Period timestamp
    /// @return totalBoostAmount The total amount of boost this period has,
    /// Returns totalVeRamAmount The total amount of veRam attached to this period
    function boostInfos(uint256 period) external view returns (uint128 totalBoostAmount, int128 totalVeRamAmount);

    /// @notice Get the period seconds debt of a specific position
    /// @param period the period number
    /// @param recipient recipient address
    /// @param index position index
    /// @param tickLower lower bound of range
    /// @param tickUpper upper bound of range
    /// @return secondsDebtX96 seconds the position was not in range for the period
    /// @return boostedSecondsDebtX96 boosted seconds the period
    function positionPeriodDebt(
        uint256 period,
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (int256 secondsDebtX96, int256 boostedSecondsDebtX96);

    /// @notice get the period seconds in range of a specific position
    /// @param period the period number
    /// @param owner owner address
    /// @param index position index
    /// @param tickLower lower bound of range
    /// @param tickUpper upper bound of range
    /// @return periodSecondsInsideX96 seconds the position was not in range for the period
    /// @return periodBoostedSecondsInsideX96 boosted seconds the period
    function positionPeriodSecondsInRange(
        uint256 period,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint256 periodSecondsInsideX96, uint256 periodBoostedSecondsInsideX96);

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
            bool initialized,
            uint160 secondsPerBoostedLiquidityPeriodX128
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IRamsesV2PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerBoostedLiquidityPeriodX128s Cumulative seconds per boosted liquidity-in-range value as of each `secondsAgos` from the current block timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s,
            uint160[] memory secondsPerBoostedLiquidityPeriodX128s
        );

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsPerBoostedLiquidityInsideX128 The snapshot of seconds per boosted liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint160 secondsPerBoostedLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IRamsesV2PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position at index 0
    /// @dev The caller of this method receives a callback in the form of IRamsesV2MintCallback#ramsesV2MintCallback
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

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IRamsesV2MintCallback#ramsesV2MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param index The index for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param veRamTokenId The veRam tokenId to attach to the position
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 veRamTokenId,
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

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param index The index of the position to be collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position at index 0
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

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param index The index for which the liquidity will be burned
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IRamsesV2SwapCallback#ramsesV2SwapCallback
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
    /// @dev The caller of this method receives a callback in the form of IRamsesV2FlashCallback#ramsesV2FlashCallback
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
pragma solidity ^0.8.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IRamsesV2PoolOwnerActions {
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
pragma solidity ^0.8.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IRamsesV2PoolEvents {
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
pragma solidity ^0.8.0;

import "./utils/IDefaultAccessControl.sol";
import "./IUnitPricesGovernance.sol";

interface IProtocolGovernance is IDefaultAccessControl, IUnitPricesGovernance {
    /// @notice CommonLibrary protocol params.
    /// @param maxTokensPerVault Max different token addresses that could be managed by the vault
    /// @param governanceDelay The delay (in secs) that must pass before setting new pending params to commiting them
    /// @param protocolTreasury The address that collects protocolFees, if protocolFee is not zero
    /// @param forceAllowMask If a permission bit is set in this mask it forces all addresses to have this permission as true
    /// @param withdrawLimit Withdraw limit (in unit prices, i.e. usd)
    struct Params {
        uint256 maxTokensPerVault;
        uint256 governanceDelay;
        address protocolTreasury;
        uint256 forceAllowMask;
        uint256 withdrawLimit;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedPermissionGrantsTimestamps(address target) external view returns (uint256);

    /// @notice Staged granted permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function stagedPermissionGrantsMasks(address target) external view returns (uint256);

    /// @notice Permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function permissionMasks(address target) external view returns (uint256);

    /// @notice Timestamp after which staged pending protocol parameters can be committed
    /// @return Zero if there are no staged parameters, timestamp otherwise.
    function stagedParamsTimestamp() external view returns (uint256);

    /// @notice Staged pending protocol parameters.
    function stagedParams() external view returns (Params memory);

    /// @notice Current protocol parameters.
    function params() external view returns (Params memory);

    /// @notice Addresses for which non-zero permissions are set.
    function permissionAddresses() external view returns (address[] memory);

    /// @notice Permission addresses staged for commit.
    function stagedPermissionGrantsAddresses() external view returns (address[] memory);

    /// @notice Return all addresses where rawPermissionMask bit for permissionId is set to 1.
    /// @param permissionId Id of the permission to check.
    /// @return A list of dirty addresses.
    function addressesByPermission(uint8 permissionId) external view returns (address[] memory);

    /// @notice Checks if address has permission or given permission is force allowed for any address.
    /// @param addr Address to check
    /// @param permissionId Permission to check
    function hasPermission(address addr, uint8 permissionId) external view returns (bool);

    /// @notice Checks if address has all permissions.
    /// @param target Address to check
    /// @param permissionIds A list of permissions to check
    function hasAllPermissions(address target, uint8[] calldata permissionIds) external view returns (bool);

    /// @notice Max different ERC20 token addresses that could be managed by the protocol.
    function maxTokensPerVault() external view returns (uint256);

    /// @notice The delay for committing any governance params.
    function governanceDelay() external view returns (uint256);

    /// @notice The address of the protocol treasury.
    function protocolTreasury() external view returns (address);

    /// @notice Permissions mask which defines if ordinary permission should be reverted.
    /// This bitmask is xored with ordinary mask.
    function forceAllowMask() external view returns (uint256);

    /// @notice Withdraw limit per token per block.
    /// @param token Address of the token
    /// @return Withdraw limit per token per block
    function withdrawLimit(address token) external view returns (uint256);

    /// @notice Addresses that has staged validators.
    function stagedValidatorsAddresses() external view returns (address[] memory);

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedValidatorsTimestamps(address target) external view returns (uint256);

    /// @notice Staged validator for the given address.
    /// @param target The given address
    /// @return Validator
    function stagedValidators(address target) external view returns (address);

    /// @notice Addresses that has validators.
    function validatorsAddresses() external view returns (address[] memory);

    /// @notice Address that has validators.
    /// @param i The number of address
    /// @return Validator address
    function validatorsAddress(uint256 i) external view returns (address);

    /// @notice Validator for the given address.
    /// @param target The given address
    /// @return Validator
    function validators(address target) external view returns (address);

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, IMMEDIATE  -------------------

    /// @notice Rollback all staged validators.
    function rollbackStagedValidators() external;

    /// @notice Revoke validator instantly from the given address.
    /// @param target The given address
    function revokeValidator(address target) external;

    /// @notice Stages a new validator for the given address
    /// @param target The given address
    /// @param validator The validator for the given address
    function stageValidator(address target, address validator) external;

    /// @notice Commits validator for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitValidator(address target) external;

    /// @notice Commites all staged validators for which governance delay passed
    /// @return Addresses for which validators were committed
    function commitAllValidatorsSurpassedDelay() external returns (address[] memory);

    /// @notice Rollback all staged granted permission grant.
    function rollbackStagedPermissionGrants() external;

    /// @notice Commits permission grants for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitPermissionGrants(address target) external;

    /// @notice Commites all staged permission grants for which governance delay passed.
    /// @return An array of addresses for which permission grants were committed.
    function commitAllPermissionGrantsSurpassedDelay() external returns (address[] memory);

    /// @notice Revoke permission instantly from the given address.
    /// @param target The given address.
    /// @param permissionIds A list of permission ids to revoke.
    function revokePermissions(address target, uint8[] memory permissionIds) external;

    /// @notice Commits staged protocol params.
    /// Reverts if governance delay has not passed yet.
    function commitParams() external;

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, DELAY  -------------------

    /// @notice Sets new pending params that could have been committed after governance delay expires.
    /// @param newParams New protocol parameters to set.
    function stageParams(Params memory newParams) external;

    /// @notice Stage granted permissions that could have been committed after governance delay expires.
    /// Resets commit delay and permissions if there are already staged permissions for this address.
    /// @param target Target address
    /// @param permissionIds A list of permission ids to grant
    function stagePermissionGrants(address target, uint8[] memory permissionIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProtocolGovernance.sol";

interface IVaultRegistry is IERC721 {
    /// @notice Get Vault for the giver NFT ID.
    /// @param nftId NFT ID
    /// @return vault Address of the Vault contract
    function vaultForNft(uint256 nftId) external view returns (address vault);

    /// @notice Get NFT ID for given Vault contract address.
    /// @param vault Address of the Vault contract
    /// @return nftId NFT ID
    function nftForVault(address vault) external view returns (uint256 nftId);

    /// @notice Checks if the nft is locked for all transfers
    /// @param nft NFT to check for lock
    /// @return `true` if locked, false otherwise
    function isLocked(uint256 nft) external view returns (bool);

    /// @notice Register new Vault and mint NFT.
    /// @param vault address of the vault
    /// @param owner owner of the NFT
    /// @return nft Nft minted for the given Vault
    function registerVault(address vault, address owner) external returns (uint256 nft);

    /// @notice Number of Vaults registered.
    function vaultsCount() external view returns (uint256);

    /// @notice All Vaults registered.
    function vaults() external view returns (address[] memory);

    /// @notice Address of the ProtocolGovernance.
    function protocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Address of the staged ProtocolGovernance.
    function stagedProtocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Minimal timestamp when staged ProtocolGovernance can be applied.
    function stagedProtocolGovernanceTimestamp() external view returns (uint256);

    /// @notice Stage new ProtocolGovernance.
    /// @param newProtocolGovernance new ProtocolGovernance
    function stageProtocolGovernance(IProtocolGovernance newProtocolGovernance) external;

    /// @notice Commit new ProtocolGovernance.
    function commitStagedProtocolGovernance() external;

    /// @notice Lock NFT for transfers
    /// @dev Use this method when vault structure is set up and should become immutable. Can be called by owner.
    /// @param nft - NFT to lock
    function lockNft(uint256 nft) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * ```solidity
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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./utils/IDefaultAccessControl.sol";

interface IUnitPricesGovernance is IDefaultAccessControl, IERC165 {
    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @return The amount of token
    function stagedUnitPrices(address token) external view returns (uint256);

    /// @notice Timestamp after which staged unit prices for the given token can be committed.
    /// @param token Address of the token
    /// @return Timestamp
    function stagedUnitPricesTimestamps(address token) external view returns (uint256);

    /// @notice Estimated amount of token worth 1 USD.
    /// @param token Address of the token
    /// @return The amount of token
    function unitPrices(address token) external view returns (uint256);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @param value The amount of token
    function stageUnitPrice(address token, uint256 value) external;

    /// @notice Reset staged value
    /// @param token Address of the token
    function rollbackUnitPrice(address token) external;

    /// @notice Commit staged unit price
    /// @param token Address of the token
    function commitUnitPrice(address token) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}