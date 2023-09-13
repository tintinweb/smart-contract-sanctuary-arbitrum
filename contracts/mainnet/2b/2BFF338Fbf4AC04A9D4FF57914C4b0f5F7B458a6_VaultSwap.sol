// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma abicoder v2;
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";

interface IVaultSwap {
    event Swap(IERC20 sellToken, IERC20 buyToken, uint256 boughtAmount);

    struct SwapParams {
        // The `sellTokenAddress` field from the API response.
        IERC20 sellToken;
        // The amount of sellToken we want to sell
        uint256 sellAmount;
        // The `buyTokenAddress` field from the API response.
        IERC20 buyToken;
        // The `allowanceTarget` field from the API response.
        address spender;
        // The `to` field from the API response.
        address payable swapTarget;
        // The `data` field from the API response.
        bytes swapCallData;
    }

    receive() external payable;

    function swap(
        SwapParams calldata params
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma abicoder v2;
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "./interfaces/IVaultSwap.sol";

contract VaultSwap is IVaultSwap {
    // The WETH contract.
    IWETH9 public immutable WETH;
    // Creator of this contract.
    address public owner;
    // 0x ExchangeProxy address.
    // See https://docs.0x.org/developer-resources/contract-addresses
    address public exchangeProxy;

    constructor(IWETH9 _weth, address _exchangeProxy) {
        WETH = _weth;
        exchangeProxy = _exchangeProxy;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable override {}

    // Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
    function swap(
        SwapParams calldata params
    )
        external
        payable
        override
        returns (uint256 boughtAmount)
    // Must attach ETH equal to the `value` field from the API response.
    {
        // Checks that the swapTarget is actually the address of 0x ExchangeProxy
        require(params.swapTarget == exchangeProxy, "Target not ExchangeProxy");
        require(params.sellToken != params.buyToken, "Same Token");

        uint256 protocolFee = msg.value;
        bool ethPayment;

        // Wrap ETH in WETH when needed
        // When sending ETH to the contract, the sellToken should be WETH
        if (
            address(params.sellToken) == address(WETH) &&
            msg.value >= params.sellAmount
        ) {
            WETH.deposit{value: params.sellAmount}();
            protocolFee = msg.value - params.sellAmount;
            ethPayment = true;
        } else {
            params.sellToken.transferFrom(
                msg.sender,
                address(this),
                params.sellAmount
            );
        }

        // Track our balance of the buyToken to determine how much we've bought.
        boughtAmount = params.buyToken.balanceOf(address(this));

        // Give `spender` an infinite allowance to spend this contract's `sellToken`.
        // Note that for some tokens (e.g., USDT, KNC), you must first reset any existing
        // allowance to 0 before being able to update it.
        require(params.sellToken.approve(params.spender, uint256(-1)));
        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, ) = params.swapTarget.call{value: protocolFee}(
            params.swapCallData
        );
        require(success, "SWAP_CALL_FAILED");

        // Use our current buyToken balance to determine how much we've bought.
        boughtAmount = params.buyToken.balanceOf(address(this)) - boughtAmount;

        // Transfer the amount bought
        params.buyToken.transfer(
            msg.sender,
            params.buyToken.balanceOf(address(this))
        );

        // Unwrap leftover WETH if crypto provided was ETH
        if (ethPayment) {
            WETH.withdraw(WETH.balanceOf(address(this)));
        }
        // Refund unswapped token back
        params.sellToken.transfer(
            msg.sender,
            params.sellToken.balanceOf(address(this))
        );
        // Refund any unspent protocol fees to the sender.
        msg.sender.transfer(address(this).balance);

        // Reset the approval
        params.sellToken.approve(params.spender, 0);
        emit Swap(params.sellToken, params.buyToken, boughtAmount);
        return boughtAmount;
    }
}