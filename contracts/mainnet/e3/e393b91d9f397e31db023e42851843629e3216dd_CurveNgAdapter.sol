/**
 *Submitted for verification at Arbiscan.io on 2024-05-31
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin-4/contracts/token/ERC20/IERC20.sol

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

// File: contracts/BIFI/strategies/Curve/CurveNgAdapter.sol


pragma solidity ^0.8.0;

// NG pools use dynamic arrays not compatible with curveRouter-v1.0
// this contract adapts add_liquidity(uint256[2] amounts) to add_liquidity(uint256[] amounts)

interface CurveStableSwapNg {
    function add_liquidity(uint256[] memory _amounts, uint256 _min_mint_amount, address _receiver) external returns (uint256);
    function coins(uint i) external view returns (address);
}

contract CurveNgAdapter {

    CurveStableSwapNg public pool;
    IERC20 public t0;
    IERC20 public t1;

    constructor(address _pool) {
        pool = CurveStableSwapNg(_pool);
        t0 = IERC20(pool.coins(0));
        t1 = IERC20(pool.coins(1));
        t0.approve(_pool, type(uint).max);
        t1.approve(_pool, type(uint).max);
    }

    function add_liquidity(uint256[2] memory _amounts, uint256 min_mint_amount) external {
        uint[] memory amounts = new uint[](2);
        amounts[0] = _amounts[0];
        amounts[1] = _amounts[1];
        if (amounts[0] > 0) t0.transferFrom(msg.sender, address(this), amounts[0]);
        if (amounts[1] > 0) t1.transferFrom(msg.sender, address(this), amounts[1]);
        CurveStableSwapNg(pool).add_liquidity(amounts, min_mint_amount, msg.sender);
    }
}