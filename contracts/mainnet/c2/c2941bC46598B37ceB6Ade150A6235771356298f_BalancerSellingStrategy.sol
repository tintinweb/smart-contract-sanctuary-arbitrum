/**
 *Submitted for verification at Arbiscan on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

interface IRewardTracker {
        function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

       function claimForAccount(address _account, address _receiver)
        external
        returns (uint256);

        function claimable(address _account) external view returns (uint256);

        function stakedAmounts(address _account) external view returns (uint256);

        function setHandler(address _address, bool _isActive) external;
}

interface IRewardCompounder {
    function compound() external;

    error Unauthorized();

    error CompoundFailed();

    error NotContract();

    event Compounded(address indexed account, uint256 wethOut, uint256 mycIn);
    event StrategyUpdated(address indexed newStrategy, address indexed oldStrategy);
}

interface ISellingStrategy {
    function sell(uint256 amountIn, address tokenIn, address tokenOut) external returns (uint256 amountOut);
}

interface IBalancerV2Swaps {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256 amountCalculated);
}

/**
 * @title Performs trade on 80WETH/20ETH Balancer V2 pool.
 * @author iflp
 * @author CalabashSquash
 */
contract BalancerSellingStrategy is ISellingStrategy {
    address constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 constant POOL_ID =
        0x432502a764abec914f940916652ce55885323cda0002000000000000000000c6;

    /**
     * @notice Sell WETH for MYC on the Balancer V2 vault's 80% WETH 20% MYC pool.
     * @param amountIn Amount of input token to sell.
     * @param weth WETH contract address.
     * @param myc MYC contract address.
     * @dev Accepts 100% slippage.
     */
    function sell(
        uint256 amountIn,
        address weth,
        address myc
    ) external returns (uint256 amountOut) {
        IBalancerV2Swaps.SingleSwap memory singleswap;
        IBalancerV2Swaps.FundManagement memory funds;

        singleswap.poolId = POOL_ID;
        singleswap.kind = IBalancerV2Swaps.SwapKind.GIVEN_IN;
        singleswap.assetIn = weth;
        singleswap.assetOut = myc;
        singleswap.amount = amountIn;

        funds.sender = address(this);
        funds.fromInternalBalance = false;
        funds.recipient = payable(address(this));
        funds.toInternalBalance = false;

        uint256 limit = 0;
        uint256 deadline = ~uint256(0);

        IERC20(weth).approve(VAULT, amountIn);
        amountOut = IBalancerV2Swaps(VAULT).swap(
            singleswap,
            funds,
            limit,
            deadline
        );
    }
}