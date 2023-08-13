// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IDefaultPoolCalc} from "../interfaces/IDefaultPoolCalc.sol";
import {IDefaultExtendedPool} from "../interfaces/IDefaultExtendedPool.sol";

import {IERC20Metadata} from "@openzeppelin/contracts-4.5.0/token/ERC20/extensions/IERC20Metadata.sol";

/// @notice DefaultPoolCalc is a contract that calculates the amount of LP tokens received
/// for a given amount of tokens deposited into a DefaultPool. This is implemented
/// because the StableSwap pool contract does not expose a function to calculate the EXACT amount,
/// only the ESTIMATED amount: `calculateTokenAmount()`.
contract DefaultPoolCalc is IDefaultPoolCalc {
    // Struct storing variables used in calculations in the
    // {add,remove}Liquidity functions to avoid stack too deep errors
    struct ManageLiquidityInfo {
        uint256 d0;
        uint256 d1;
        uint256 preciseA;
        uint256 totalSupply;
        uint256[] balances;
        uint256[] multipliers;
    }

    uint256 internal constant A_PRECISION = 100;
    uint256 internal constant FEE_DENOMINATOR = 10**10;

    // Copied from the Saddle repo with state changes omitted: https://github.com/saddle-finance/saddle-contract/
    // blob/5d538c47115c29990dea5aa8af679bd024c82e35/contracts/SwapUtilsV2.sol#L717

    /// @inheritdoc IDefaultPoolCalc
    function calculateAddLiquidity(address pool, uint256[] memory amounts) external view returns (uint256 amountOut) {
        // Get the provided number of tokens. We will later verify that it matches actual number of tokens in the pool.
        uint256 numTokens = amounts.length;
        // (1) Verify that `pool.tokens.length <= numTokens`
        _verifyTokensLengthCeiling(pool, numTokens);
        (, , , , uint256 swapFee, , address lpToken) = IDefaultExtendedPool(pool).swapStorage();
        // current state
        ManageLiquidityInfo memory v = ManageLiquidityInfo({
            d0: 0,
            d1: 0,
            preciseA: IDefaultExtendedPool(pool).getAPrecise(),
            totalSupply: IERC20Metadata(lpToken).totalSupply(),
            balances: new uint256[](numTokens),
            multipliers: new uint256[](numTokens)
        });
        uint256[] memory newBalances = new uint256[](numTokens);
        // (2) If `pool.tokens.length < numTokens`, the loop will revert when reading token at index `numTokens - 1`.
        for (uint256 i = 0; i < numTokens; ++i) {
            address token = IDefaultExtendedPool(pool).getToken(uint8(i));
            v.balances[i] = IDefaultExtendedPool(pool).getTokenBalance(uint8(i));
            newBalances[i] = v.balances[i] + amounts[i];
            v.multipliers[i] = 10**(18 - IERC20Metadata(token).decimals());
        }
        // (1) + (2) implies that `pool.tokens.length == numTokens`
        if (v.totalSupply != 0) {
            v.d0 = _getD(_xp(v.balances, v.multipliers), v.preciseA);
        } else {
            for (uint256 i = 0; i < numTokens; ++i) {
                require(amounts[i] > 0, "Must supply all tokens in pool");
            }
        }

        // invariant after change
        v.d1 = _getD(_xp(newBalances, v.multipliers), v.preciseA);
        require(v.d1 > v.d0, "D should increase");

        if (v.totalSupply == 0) {
            return v.d1;
        } else {
            uint256 feePerToken = _feePerToken(swapFee, numTokens);
            for (uint256 i = 0; i < numTokens; ++i) {
                uint256 idealBalance = (v.d1 * v.balances[i]) / v.d0;
                uint256 fees = (feePerToken * _difference(idealBalance, newBalances[i])) / FEE_DENOMINATOR;
                newBalances[i] -= fees;
            }
            v.d1 = _getD(_xp(newBalances, v.multipliers), v.preciseA);
            return ((v.d1 - v.d0) * v.totalSupply) / v.d0;
        }
    }

    /// @dev Verifies that `pool.tokens.length <= numTokens`. Reverts if `pool.tokens.length > numTokens`.
    function _verifyTokensLengthCeiling(address pool, uint256 numTokens) internal view {
        // We will attempt to read the token at index `numTokens`.
        try IDefaultExtendedPool(pool).getToken(uint8(numTokens)) returns (address) {
            // If call succeeds, if means that `numTokens < pool.tokens.length`,
            // which is the undesired outcome, so we revert.
            revert("Incorrect tokens amount");
        } catch {
            // solhint-disable-previous-line no-empty-blocks
            // If the call fails, it means that `numTokens >= pool.tokens.length`,
            // which is the desired outcome, so we continue.
        }
    }

    // ═════════════════════════════════════════════ STABLE SWAP MATH ══════════════════════════════════════════════════

    // Copied from https://github.com/saddle-finance/saddle-contract/blob/master/contracts/SwapUtilsV2.sol

    /// @dev Returns abs(a-b).
    function _difference(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    /**
     * @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
     * @param xp a precision-adjusted set of pool balances. Array should be the same cardinality
     * as the pool.
     * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
     * See the StableSwap paper for details
     * @return the invariant, at the precision of the pool
     */
    function _getD(uint256[] memory xp, uint256 a) internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        uint256 s;
        for (uint256 i = 0; i < numTokens; i++) {
            s = s + xp[i];
        }
        if (s == 0) {
            return 0;
        }

        uint256 prevD;
        uint256 d = s;
        uint256 nA = a * numTokens;

        for (uint256 i = 0; i < 256; i++) {
            uint256 dP = d;
            for (uint256 j = 0; j < numTokens; j++) {
                dP = (dP * d) / (xp[j] * numTokens);
                // If we were to protect the division loss we would have to keep the denominator separate
                // and divide at the end. However this leads to overflow with large numTokens or/and D.
                // dP = dP * D * D * D * ... overflow!
            }
            prevD = d;
            d =
                ((((nA * s) / A_PRECISION) + (dP * numTokens)) * d) /
                ((((nA - A_PRECISION) * d) / A_PRECISION) + ((numTokens + 1) * dP));

            if (_difference(d, prevD) <= 1) {
                return d;
            }
        }

        // Convergence should occur in 4 loops or less. If this is reached, there may be something wrong
        // with the pool. If this were to occur repeatedly, LPs should withdraw via `removeLiquidity()`
        // function which does not rely on D.
        revert("D does not converge");
    }

    /**
     * @notice internal helper function to calculate fee per token multiplier used in
     * swap fee calculations
     * @param swapFee swap fee for the tokens
     * @param numTokens number of tokens pooled
     */
    function _feePerToken(uint256 swapFee, uint256 numTokens) internal pure returns (uint256) {
        return ((swapFee * numTokens) / ((numTokens - 1) * 4));
    }

    /**
     * @notice Given a set of balances and precision multipliers, return the
     * precision-adjusted balances.
     *
     * @param balances an array of token balances, in their native precisions.
     * These should generally correspond with pooled tokens.
     *
     * @param precisionMultipliers an array of multipliers, corresponding to
     * the amounts in the balances array. When multiplied together they
     * should yield amounts at the pool's precision.
     *
     * @return an array of amounts "scaled" to the pool's precision
     */
    function _xp(uint256[] memory balances, uint256[] memory precisionMultipliers)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 numTokens = balances.length;
        require(numTokens == precisionMultipliers.length, "Balances must match multipliers");
        uint256[] memory xp = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            xp[i] = balances[i] * precisionMultipliers[i];
        }
        return xp;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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