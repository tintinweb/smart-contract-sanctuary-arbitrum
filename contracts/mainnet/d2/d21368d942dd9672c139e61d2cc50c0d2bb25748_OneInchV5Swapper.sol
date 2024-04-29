// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.20;

import {IGenericRouter, IAggregationExecutor, IERC20} from "src/interfaces/swap/IGenericRouter.sol";
import {ITokenSwapper} from "src/interfaces/swap/ITokenSwapper.sol";

contract OneInchV5Swapper is ITokenSwapper {
    struct SwapParams {
        address executor;
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
        bytes data;
    }

    IGenericRouter public router;

    address executor = 0xE37e799D5077682FA0a244D46E5649F71457BD09;

    constructor(address _router) {
        router = IGenericRouter(payable(_router));
    }

    /*
    * @param externalData A bytes value containing the encoded swap parameters.
    * @return The actual amount of `tokenOut` received in the swap.
    */
    function swap(address tokenIn, uint256 amountIn, address tokenOut, uint256 minAmountOut, bytes memory externalData)
        external
        returns (uint256 amountOut)
    {
        SwapParams memory _swap;

        (_swap.executor, _swap.srcToken, _swap.dstToken,,, _swap.amount, _swap.minReturnAmount,,, _swap.data) = abi
            .decode(externalData, (address, address, address, address, address, uint256, uint256, uint256, bytes, bytes));

        if (tokenIn != _swap.srcToken) {
            revert InvalidTokenIn(tokenIn, _swap.srcToken);
        }

        if (amountIn < _swap.amount) {
            revert InvalidAmountIn(amountIn, _swap.amount);
        }

        if (tokenOut != _swap.dstToken) {
            revert InvalidTokenOut(tokenOut, _swap.dstToken);
        }

        if (minAmountOut > _swap.minReturnAmount) {
            revert InvalidMinAmountOut(minAmountOut, _swap.minReturnAmount);
        }

        IERC20(_swap.srcToken).transferFrom(msg.sender, address(this), _swap.amount);
        IERC20(_swap.srcToken).approve(address(router), _swap.amount);

        (amountOut,) = router.swap(
            IAggregationExecutor(_swap.executor),
            IGenericRouter.SwapDescription({
                srcToken: IERC20(_swap.srcToken),
                dstToken: IERC20(_swap.dstToken),
                srcReceiver: payable(_swap.executor),
                dstReceiver: payable(address(this)),
                amount: _swap.amount,
                minReturnAmount: _swap.minReturnAmount,
                flags: 4
            }),
            "",
            _swap.data
        );

        IERC20(_swap.dstToken).transfer(msg.sender, amountOut);

        return amountOut;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

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

/// @title Interface for making arbitrary calls during swap
interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable; // 0x4b64e492
}

interface IGenericRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    /// @notice Performs a swap, delegating all calls encoded in `data` to `executor`. See tests for usage examples
    /// @dev router keeps 1 wei of every token on the contract balance for gas optimisations reasons. This affects first swap of every token by leaving 1 wei on the contract.
    /// @param executor Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount Resulting token amount
    /// @return spentAmount Source token amount
    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// token swapper for Butter (tokenin => Butter)
interface ITokenSwapper {
    function swap(address tokenIn, uint256 amountIn, address tokenOut, uint256 minAmountOut, bytes memory externalData)
        external
        returns (uint256 amountOut);

    error EmptyTokenIn();
    error EmptyTokenOut();
    error EmptyRouter();
    error EmptyPath();
    error InvalidPathSegment(address from, address next);
    error InvalidAmountIn(uint256 amountIn, uint256 referenceAmount);
    error InvalidMinAmountOut(uint256 minAmountOut, uint256 referenceAmount);
    error InvalidTokenIn(address tokenIn, address referenceToken);
    error InvalidTokenOut(address tokenOut, address referenceToken);
    error InvalidReceiver(address receiver, address referenceReceiver);
    error Slippage(uint256 amountOut, uint256 minAmountOut);
}