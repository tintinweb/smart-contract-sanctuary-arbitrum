// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts-4.8.0/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts-4.8.0/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts-4.8.0/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts-4.8.0/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts-4.8.0/security/ReentrancyGuard.sol";

import {IPrivateFactory} from "./interfaces/IPrivateFactory.sol";
import {IPrivatePool} from "./interfaces/IPrivatePool.sol";

/// @title Private pool for concentrated liquidity
/// @notice Allows LP to offer fixed price quote in private pool to bridgers for tighter prices
/// @dev Obeys constant sum P * x + y = D curve, where P is fixed price and D is liquidity
/// @dev Functions use same signatures as Swap.sol for easier integration
contract PrivatePool is IPrivatePool, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 internal constant wad = 1e18;
    uint256 internal constant PRICE_BOUND = 0.005e18; // 50 bps in wad

    uint256 public constant PRICE_MIN = wad - PRICE_BOUND; // 1 - 50bps in wad
    uint256 public constant PRICE_MAX = wad + PRICE_BOUND; // 1 + 50bps in wad
    uint256 public constant FEE_MAX = 0.0001e18; // 1 bps in wad
    uint256 public constant ADMIN_FEE_MAX = 1e18; // 100% of swap fees in wad

    address public immutable factory;
    address public immutable owner;

    address public immutable token0; // base token
    address public immutable token1; // quote token

    uint256 internal immutable token0Decimals;
    uint256 internal immutable token1Decimals;

    uint256 public P; // fixed price param: amount of token1 per amount of token0 in wad
    uint256 public fee; // fee charged on swap; acts as LP's bid/ask spread
    uint256 public adminFee; // % of swap fee to protocol

    uint256 public protocolFees0;
    uint256 public protocolFees1;

    modifier onlyFactory() {
        require(msg.sender == factory, "!factory");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier onlyToken(uint8 index) {
        require(index <= 1, "invalid token index");
        _;
    }

    modifier deadlineCheck(uint256 deadline) {
        require(block.timestamp <= deadline, "block.timestamp > deadline");
        _;
    }

    event Quote(uint256 price);
    event NewSwapFee(uint256 newSwapFee);
    event NewAdminFee(uint256 newAdminFee);
    event TokenSwap(address indexed buyer, uint256 tokensSold, uint256 tokensBought, uint128 soldId, uint128 boughtId);
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256 lpTokenSupply);
    event Skim(address indexed recipient, uint256[] tokenAmounts);

    constructor(
        address _owner,
        address _token0,
        address _token1,
        uint256 _P,
        uint256 _fee,
        uint256 _adminFee
    ) {
        factory = msg.sender;
        owner = _owner;
        token0 = _token0;
        token1 = _token1;

        // limit to tokens with decimals <= 18
        uint256 _token0Decimals = IERC20Metadata(_token0).decimals();
        require(_token0Decimals <= 18, "token0 decimals > 18");
        token0Decimals = _token0Decimals;

        uint256 _token1Decimals = IERC20Metadata(_token1).decimals();
        require(_token1Decimals <= 18, "token1 decimals > 18");
        token1Decimals = _token1Decimals;

        // initialize price, fee, admin fee
        require(_P >= PRICE_MIN && _P <= PRICE_MAX, "price out of range");
        P = _P;

        require(_fee <= FEE_MAX, "fee > max");
        fee = _fee;

        require(_adminFee <= ADMIN_FEE_MAX, "adminFee > max");
        adminFee = _adminFee;
    }

    /// @notice Updates the quote price LP is willing to offer tokens at
    /// @param _P The new fixed price LP is willing to buy and sell at
    function quote(uint256 _P) external onlyOwner {
        require(_P >= PRICE_MIN && _P <= PRICE_MAX, "price out of range");
        require(_P != P, "same price");

        // set new P price param
        P = _P;

        emit Quote(_P);
    }

    /// @notice Updates the fee applied on swaps
    /// @dev Effectively acts as bid/ask spread for LP
    /// @param _fee The new swap fee
    function setSwapFee(uint256 _fee) external onlyOwner {
        require(_fee <= FEE_MAX, "fee > max");
        fee = _fee;
        emit NewSwapFee(_fee);
    }

    /// @notice Updates the admin fee applied on private pool swaps
    /// @dev Admin fees sent to factory owner
    /// @param _fee The new admin fee
    function setAdminFee(uint256 _fee) external onlyFactory {
        require(_fee <= ADMIN_FEE_MAX, "adminFee > max");
        adminFee = _fee;
        emit NewAdminFee(_fee);
    }

    /// @notice Adds liquidity to pool
    /// @param amounts The token amounts to add in token decimals
    /// @param deadline The deadline before which liquidity must be added
    function addLiquidity(uint256[] memory amounts, uint256 deadline)
        external
        onlyOwner
        deadlineCheck(deadline)
        returns (uint256 minted_)
    {
        require(amounts.length == 2, "invalid amounts");

        // get current token balances in pool
        uint256 xBal = IERC20(token0).balanceOf(address(this));
        uint256 yBal = IERC20(token1).balanceOf(address(this));

        // convert balances to wad for liquidity calcs adjusted for protocol fees
        uint256 xWad = _amountWad(xBal - protocolFees0, true);
        uint256 yWad = _amountWad(yBal - protocolFees1, false);

        // get D balance before add liquidity
        uint256 _d = _D(xWad, yWad);

        // transfer amounts in decimals in
        if (amounts[0] > 0) IERC20(token0).safeTransferFrom(msg.sender, address(this), amounts[0]);
        if (amounts[1] > 0) IERC20(token1).safeTransferFrom(msg.sender, address(this), amounts[1]);

        // update amounts for actual transfer amount in case of fees on transfer
        amounts[0] = IERC20(token0).balanceOf(address(this)) - xBal;
        amounts[1] = IERC20(token1).balanceOf(address(this)) - yBal;

        // convert amounts to wad for calcs
        uint256 amount0Wad = _amountWad(amounts[0], true);
        uint256 amount1Wad = _amountWad(amounts[1], false);

        // balances after transfer
        xWad += amount0Wad;
        yWad += amount1Wad;

        // calc diff with new D value
        minted_ = _D(xWad, yWad) - _d;
        _d += minted_;

        uint256[] memory fees = new uint256[](2);
        emit AddLiquidity(msg.sender, amounts, fees, _d, _d);
    }

    /// @notice Removes liquidity from pool
    /// @param amounts The token amounts to remove in token decimals
    /// @param deadline The deadline before which liquidity must be removed
    function removeLiquidity(uint256[] memory amounts, uint256 deadline)
        external
        onlyOwner
        deadlineCheck(deadline)
        returns (uint256 burned_)
    {
        require(amounts.length == 2, "invalid amounts");

        // get current token balances in pool
        uint256 xBal = IERC20(token0).balanceOf(address(this));
        uint256 yBal = IERC20(token1).balanceOf(address(this));
        require(amounts[0] + protocolFees0 <= xBal, "dx > max");
        require(amounts[1] + protocolFees1 <= yBal, "dy > max");

        // convert balances to wad for liquidity calcs adjusted for protocol fees
        uint256 xWad = _amountWad(xBal - protocolFees0, true);
        uint256 yWad = _amountWad(yBal - protocolFees1, false);

        // get D balance before remove liquidity
        uint256 _d = _D(xWad, yWad);

        // transfer amounts out
        if (amounts[0] > 0) IERC20(token0).safeTransfer(msg.sender, amounts[0]);
        if (amounts[1] > 0) IERC20(token1).safeTransfer(msg.sender, amounts[1]);

        // update amounts for actual transfer amount in case of fees on transfer
        amounts[0] = xBal - IERC20(token0).balanceOf(address(this));
        amounts[1] = yBal - IERC20(token1).balanceOf(address(this));

        // convert amounts to wad for calcs
        uint256 amount0Wad = _amountWad(amounts[0], true);
        uint256 amount1Wad = _amountWad(amounts[1], false);

        // balances after transfer
        xWad -= amount0Wad;
        yWad -= amount1Wad;

        // calc diff with new D value
        burned_ = _d - _D(xWad, yWad);
        _d -= burned_;

        emit RemoveLiquidity(msg.sender, amounts, _d);
    }

    /// @notice Swaps token from for an amount of token to
    /// @param tokenIndexFrom The index of the token in
    /// @param tokenIndexTo The index of the token out
    /// @param dx The amount of token in in token decimals
    /// @param minDy The minimum amount of token out in token decimals
    /// @param deadline The deadline before which swap must be executed
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    )
        external
        nonReentrant
        onlyToken(tokenIndexFrom)
        onlyToken(tokenIndexTo)
        deadlineCheck(deadline)
        returns (uint256 dy_)
    {
        require(tokenIndexFrom != tokenIndexTo, "invalid token swap");

        // get current token in balance in pool
        address tokenIn = tokenIndexFrom == 0 ? token0 : token1;
        uint256 bal = IERC20(tokenIn).balanceOf(address(this));

        // transfer in tokens and update dx (in case of transfer fees)
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), dx);
        dx = IERC20(tokenIn).balanceOf(address(this)) - bal;

        // calculate amount out from swap
        // @dev returns zero if amount out exceeds pool balance
        uint256 dyAdminFee;
        (dy_, dyAdminFee) = _calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
        require(dy_ > 0, "dy > pool balance");
        require(dy_ >= minDy, "dy < minDy");

        if (tokenIndexTo == 0) {
            // update admin fee reserves
            protocolFees0 += dyAdminFee;

            // transfer dy out to swapper
            address tokenOut = token0;
            IERC20(tokenOut).safeTransfer(msg.sender, dy_);
        } else {
            // update admin fee reserves
            protocolFees1 += dyAdminFee;

            // transfer dy out to swapper
            address tokenOut = token1;
            IERC20(tokenOut).safeTransfer(msg.sender, dy_);
        }

        emit TokenSwap(msg.sender, dx, dy_, tokenIndexFrom, tokenIndexTo);
    }

    /// @notice Transfers protocol fees out
    /// @param recipient The recipient address of the aggregated admin fees
    function skim(address recipient) external onlyFactory {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = protocolFees0;
        amounts[1] = protocolFees1;

        // clear protocol fees
        protocolFees0 = 0;
        protocolFees1 = 0;

        // send out to factory owner
        if (amounts[0] > 0) IERC20(token0).safeTransfer(recipient, amounts[0]);
        if (amounts[1] > 0) IERC20(token1).safeTransfer(recipient, amounts[1]);

        emit Skim(recipient, amounts);
    }

    /// @notice Address of the pooled token at given index
    /// @dev Reverts for invalid token index
    /// @param index The index of the token
    function getToken(uint8 index) external view onlyToken(index) returns (IERC20) {
        address token = index == 0 ? token0 : token1;
        return IERC20(token);
    }

    /// @notice D liquidity for current pool balance state
    function D() external view returns (uint256) {
        uint256 xBalAdjusted = IERC20(token0).balanceOf(address(this)) - protocolFees0;
        uint256 yBalAdjusted = IERC20(token1).balanceOf(address(this)) - protocolFees1;

        uint256 xAdjustedWad = _amountWad(xBalAdjusted, true);
        uint256 yAdjustedWad = _amountWad(yBalAdjusted, false);

        return _D(xAdjustedWad, yAdjustedWad);
    }

    /// @notice Calculates amount of tokens received on swap
    /// @dev Returns zero if pool balances exceeded on swap or invalid inputs
    /// @param tokenIndexFrom The index of the token in
    /// @param tokenIndexTo The index of the token out
    /// @param dx The amount of token in in token decimals
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256 dy_) {
        (dy_, ) = _calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
    }

    /// @notice D liquidity param given pool token balances
    /// @param xWad Balance of x tokens in wad
    /// @param yWad Balance of y tokens in wad
    function _D(uint256 xWad, uint256 yWad) internal view returns (uint256) {
        return Math.mulDiv(xWad, P, wad) + yWad;
    }

    /// @notice Amount of token in wad
    /// @param dx Amount of token in token decimals
    /// @param isToken0 Whether token is token0
    function _amountWad(uint256 dx, bool isToken0) internal view returns (uint256) {
        uint256 factor = isToken0 ? 10**(token0Decimals) : 10**(token1Decimals);
        return Math.mulDiv(dx, wad, factor);
    }

    /// @notice Amount of token in token decimals
    /// @param amount Amount of token in wad
    /// @param isToken0 Whether token is token0
    function _amountDecimals(uint256 amount, bool isToken0) internal view returns (uint256) {
        uint256 factor = isToken0 ? 10**(token0Decimals) : 10**(token1Decimals);
        return Math.mulDiv(amount, factor, wad);
    }

    /// @notice Calculates amount of tokens received on swap
    /// @dev Returns zero if pool balances exceeded on swap or invalid inputs
    /// @param tokenIndexFrom The index of the token in
    /// @param tokenIndexTo The index of the token out
    /// @param dx The amount of token in in token decimals
    function _calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) internal view returns (uint256 dy_, uint256 dyAdminFee_) {
        if (tokenIndexFrom > 1 || tokenIndexTo > 1 || tokenIndexFrom == tokenIndexTo) return (0, 0);

        // convert to an amount in wad
        uint256 amountInWad = _amountWad(dx, tokenIndexFrom == 0);

        // calculate swap amount out wad
        // @dev obeys P * x + y = D
        uint256 amountOutWad;
        if (tokenIndexFrom == 0) {
            amountOutWad = Math.mulDiv(amountInWad, P, wad);

            // check amount out won't exceed pool balance
            uint256 yWad = _amountWad(IERC20(token1).balanceOf(address(this)) - protocolFees1, false);
            if (amountOutWad > yWad) return (0, 0);
        } else {
            amountOutWad = Math.mulDiv(amountInWad, wad, P);

            // check amount out won't exceed pool balance
            uint256 xWad = _amountWad(IERC20(token0).balanceOf(address(this)) - protocolFees0, true);
            if (amountOutWad > xWad) return (0, 0);
        }

        // apply swap fee on amount out
        uint256 amountSwapFeeWad = Math.mulDiv(amountOutWad, fee, wad);
        amountOutWad -= amountSwapFeeWad;

        // calculate admin fee on the total swap fee
        uint256 amountAdminFeeWad = Math.mulDiv(amountSwapFeeWad, adminFee, wad);

        // convert amount out to decimals
        dy_ = _amountDecimals(amountOutWad, tokenIndexTo == 0);
        dyAdminFee_ = _amountDecimals(amountAdminFeeWad, tokenIndexTo == 0);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Private factory for concentrated liquidity
/// @notice Deploys individual private pools owned by LPs
interface IPrivateFactory {
    function bridge() external view returns (address);

    function pool(
        address lp,
        address tokenA,
        address tokenB
    ) external view returns (address);

    function owner() external view returns (address);

    function orderTokens(address tokenA, address tokenB) external view returns (address, address);

    function deploy(
        address lp,
        address tokenA,
        address tokenB,
        uint256 P,
        uint256 fee,
        uint256 adminFee
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts-4.8.0/token/ERC20/IERC20.sol";

/// @title Private pool for concentrated liquidity
/// @notice Allows LP to offer fixed price quote in private pool to bridgers for tighter prices
/// @dev Obeys constant sum P * x + y = D curve, where P is fixed price and D is liquidity
/// @dev Functions use same signatures as Swap.sol for easier integration
interface IPrivatePool {
    function factory() external view returns (address);

    function owner() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function P() external view returns (uint256);

    function fee() external view returns (uint256);

    function adminFee() external view returns (uint256);

    /// @notice Updates the quote price LP is willing to offer tokens at
    /// @param _P The new fixed price LP is willing to buy and sell at
    function quote(uint256 _P) external;

    /// @notice Updates the fee applied on swaps
    /// @dev Effectively acts as bid/ask spread for LP
    /// @param _fee The new swap fee
    function setSwapFee(uint256 _fee) external;

    /// @notice Updates the admin fee applied on private pool swaps
    /// @dev Admin fees sent to factory owner
    /// @param _fee The new admin fee
    function setAdminFee(uint256 _fee) external;

    /// @notice Adds liquidity to pool
    /// @param amounts The token amounts to add in token decimals
    /// @param deadline The deadline before which liquidity must be added
    function addLiquidity(uint256[] calldata amounts, uint256 deadline) external returns (uint256 minted_);

    /// @notice Removes liquidity from pool
    /// @param amounts The token amounts to remove in token decimals
    /// @param deadline The deadline before which liquidity must be removed
    function removeLiquidity(uint256[] calldata amounts, uint256 deadline) external returns (uint256 burned_);

    /// @notice Swaps token from for an amount of token to
    /// @param tokenIndexFrom The index of the token in
    /// @param tokenIndexTo The index of the token out
    /// @param dx The amount of token in in token decimals
    /// @param minDy The minimum amount of token out in token decimals
    /// @param deadline The deadline before which swap must be executed
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256 dy_);

    /// @notice Transfers protocol fees out
    /// @param recipient The recipient address of the aggregated admin fees
    function skim(address recipient) external;

    /// @notice Calculates amount of tokens received on swap
    /// @dev Reverts if either token index is invalid
    /// @param tokenIndexFrom The index of the token in
    /// @param tokenIndexTo The index of the token out
    /// @param dx The amount of token in in token decimals
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256 dy_);

    /// @notice Address of the pooled token at given index
    /// @dev Reverts for invalid token index
    /// @param index The index of the token
    function getToken(uint8 index) external view returns (IERC20);

    /// @notice D liquidity for current pool balance state
    function D() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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