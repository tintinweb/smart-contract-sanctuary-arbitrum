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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IOpenOceanCaller {
    struct CallDescription {
        uint256 target;
        uint256 gasLimit;
        uint256 value;
        bytes data;
    }

    function makeCall(CallDescription memory desc) external;

    function makeCalls(CallDescription[] memory desc) external payable;
}

interface IOpenOceanExchange {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 guaranteedAmount;
        uint256 flags;
        address referrer;
        bytes permit;
    }

    function swap(
        IOpenOceanCaller caller,
        SwapDescription calldata desc,
        IOpenOceanCaller.CallDescription[] calldata calls
    ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { IOpenOceanExchange, IOpenOceanCaller } from '../../interfaces/IOpenOceanExchange.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library OpenOceanAggregator {
    // =============================================================
    //                         Errors
    // =============================================================

    error WRONG_TOKEN_IN(); // 0xf6b8648c
    error WRONG_TOKEN_OUT(); // 0x5e8f1f5b
    error WRONG_AMOUNT(); // 0xc6ea1a16
    error WRONG_DST(); // 0xcb0b65a6
    error SWAP_ERROR(); // 0xcbe60bba
    error SWAP_METHOD_NOT_IDENTIFIED(); // 0xc257a710

    // =============================================================
    //                        Constants
    // =============================================================

    address constant router = 0x6352a56caadC4F1E25CD6c75970Fa768A3304e64;

    // =============================================================
    //                        Functions
    // =============================================================

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        bytes calldata data
    ) public returns (uint256 outAmount) {
        IERC20(tokenIn).approve(address(router), amount);

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        bytes4 method = _getMethod(data);

        // swap
        if (
            method ==
            bytes4(
                keccak256(
                    'swap(address,(address,address,address,address,uint256,uint256,uint256,uint256,address,bytes),(uint256,uint256,uint256,bytes)[])'
                )
            )
        ) {
            (, IOpenOceanExchange.SwapDescription memory desc, ) = abi.decode(
                data[4:],
                (IOpenOceanCaller, IOpenOceanExchange.SwapDescription, IOpenOceanCaller.CallDescription[])
            );

            if (tokenIn != address(desc.srcToken)) revert WRONG_TOKEN_IN();
            if (tokenOut != address(desc.dstToken)) revert WRONG_TOKEN_OUT();
            if (amount != desc.amount) revert WRONG_AMOUNT();
            if (address(this) != desc.dstReceiver) revert WRONG_DST();

            _callOpenOcean(data);
        }
        // uniswapV3SwapTo
        else if (method == bytes4(keccak256('uniswapV3SwapTo(address,uint256,uint256,uint256[])'))) {
            (address recipient, uint256 swapAmount, , ) = abi.decode(data[4:], (address, uint256, uint256, uint256[]));
            if (address(this) != recipient) revert WRONG_DST();
            if (amount != swapAmount) revert WRONG_AMOUNT();

            _callOpenOcean(data);
        }
        // callUniswapTo
        else if (method == bytes4(keccak256('callUniswapTo(address,uint256,uint256,bytes32[],address)'))) {
            (address srcToken, uint256 swapAmount, , , address recipient) = abi.decode(
                data[4:],
                (address, uint256, uint256, bytes32[], address)
            );
            if (tokenIn != srcToken) revert WRONG_TOKEN_IN();
            if (amount != swapAmount) revert WRONG_AMOUNT();
            if (address(this) != recipient) revert WRONG_DST();

            _callOpenOcean(data);
        } else {
            revert SWAP_METHOD_NOT_IDENTIFIED();
        }

        return IERC20(tokenOut).balanceOf(address(this)) - balanceBefore;
    }

    function _getMethod(bytes memory data) internal pure returns (bytes4 method) {
        assembly {
            method := mload(add(data, add(32, 0)))
        }
    }

    function _callOpenOcean(bytes memory data) internal {
        (bool success, bytes memory result) = address(router).call(data);
        if (!success) {
            if (result.length < 68) revert SWAP_ERROR();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}