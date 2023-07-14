// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { IUniswapV2Router02 } from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import { IQuoterV2 } from '@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol';
import { ISwapRouter } from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

import { TransferHelper } from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

import { IWETH9 } from './interfaces/IWETH9.sol';
import { IBatchSwap } from './interfaces/IBatchSwap.sol';

contract BatchSwap is Ownable {
	/** Errors */
	error InsufficientAmountOut();
	error InvalidSwap();
	error SushiswapFail();
	error FeeTooHigh();
	error Locked();
	error NotLocked();

	/** Data Types */

	enum Protocol { UniswapV3, SushiSwap, WETH }

	enum Lock { __, UNLOCKED, LOCKED }

	struct Swap {
		Protocol protocol;
		address tokenA;
		address tokenB;
		uint24 poolFee;    // Only for UniswapV3
		uint256 amountIn;  // Only for first swap
	}

	/** Immutables */

	ISwapRouter public immutable uniswapRouter;          // 0xE592427A0AEce92De3Edee1F18E0157C05861564
	IQuoterV2 public immutable uniswapQuoter;            // 0x61fFE014bA17989E743c5F6cB21bF9697530B21e
	IUniswapV2Router02 public immutable sushiswapRouter; // 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
	IWETH9 public immutable weth;    					 // 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1

	/** Storage */

	address public treasury;
	uint256 public fee;

	Lock lock;

	/** Modifiers */

	modifier useLock {
		if (lock == Lock.LOCKED) {
			revert Locked();
		}

		lock = Lock.LOCKED;

		_;

		lock = Lock.UNLOCKED;
	}

	modifier duringLock {
		if (lock == Lock.UNLOCKED) {
			revert NotLocked();
		}
		_;
	}

	/** Constructor */

	constructor(ISwapRouter _uniswapRouter, IQuoterV2 _uniswapQuoter, IUniswapV2Router02 _sushiswapRouter, IWETH9 _weth, address _treasury, uint256 _fee) {
		if(_fee > 100_000) {
			revert FeeTooHigh();
		}

		uniswapRouter = _uniswapRouter;
		uniswapQuoter = _uniswapQuoter;

		sushiswapRouter = _sushiswapRouter;

		weth = _weth;

		treasury = _treasury;
		fee = _fee;

		lock = Lock.UNLOCKED;
	}

	/** External Functions */

    function singleSwap(Swap memory swap, uint256 minAmountOut, address recipient) external payable useLock {
		if(_isWethDeposit(swap)) {
			if(msg.value != swap.amountIn) {
				revert InvalidSwap();
			}
		} else {
			if(msg.value > 0) {
				revert InvalidSwap();
			}

			TransferHelper.safeTransferFrom(swap.tokenA, msg.sender, address(this), swap.amountIn);
		}

		if(treasury != address(0) && fee != 0) {
			uint256 swapFee = swap.amountIn * fee / 1_000_000;
			if(_isWethDeposit(swap)) {
				TransferHelper.safeTransferETH(treasury, swapFee);
			} else {
				TransferHelper.safeTransfer(swap.tokenA, treasury, swapFee);
			}
			swap.amountIn -= swapFee;
		}

		uint256 amountOut;
		if(swap.protocol == Protocol.UniswapV3) {
			amountOut = _uniswapSwap(swap, recipient);
		} else if(swap.protocol == Protocol.SushiSwap) {
			amountOut = _sushiswapSwap(swap, recipient);
		} else {
			amountOut = _wethSwap(swap, recipient);
		}

		if(amountOut < minAmountOut) {
			revert InsufficientAmountOut();
		}
	}

    function batchSwap(Swap[] memory swap, uint256 minAmountOut, address recipient) external payable useLock {
        if (swap.length <= 1) {
			revert InvalidSwap();
		}

		if(_isWethDeposit(swap[0])) {
			if(msg.value != swap[0].amountIn) {
				revert InvalidSwap();
			}
		} else {
			if(msg.value > 0) {
				revert InvalidSwap();
			}

			TransferHelper.safeTransferFrom(swap[0].tokenA, msg.sender, address(this), swap[0].amountIn);
		}

		if(treasury != address(0) && fee != 0) {
			uint256 swapFee = swap[0].amountIn * fee / 1_000_000;
			if(_isWethDeposit(swap[0])) {
				TransferHelper.safeTransferETH(treasury, swapFee);
			} else {
				TransferHelper.safeTransfer(swap[0].tokenA, treasury, swapFee);
			}
			swap[0].amountIn -= swapFee;
		}

		uint256 lastAmountOut;
        for(uint256 i = 0; i < swap.length; i++) {
			if(i != 0) {
				swap[i].amountIn = lastAmountOut;
			}

		    if(swap[i].protocol == Protocol.UniswapV3) {
		    	lastAmountOut = _uniswapSwap(swap[i], i == swap.length - 1 ? recipient : address(this));
		    } else if(swap[i].protocol == Protocol.SushiSwap) {
		    	lastAmountOut = _sushiswapSwap(swap[i], i == swap.length - 1 ? recipient : address(this));
		    } else {
				lastAmountOut = _wethSwap(swap[i], i == swap.length - 1 ? recipient : address(this));
			}
        }

		if(lastAmountOut < minAmountOut) {
			revert InsufficientAmountOut();
		}
	}

	/** View Functions */

    function singleSwapEstimateAmountOut(Swap memory swap) external returns(uint256) {
		if(treasury != address(0) && fee != 0) {
			uint256 swapFee = swap.amountIn * fee / 1_000_000;
			swap.amountIn -= swapFee;
		}

		uint256 amountOut;
		if(swap.protocol == Protocol.UniswapV3) {
			amountOut = _uniswapEstimateAmountOut(swap);
		} else if(swap.protocol == Protocol.SushiSwap) {
			amountOut = _sushiswapEstimateAmountOut(swap);
		} else {
			amountOut = swap.amountIn; // WETH -> ETH is 1 -> 1
		}

		return amountOut;
	}

    function batchSwapEstimateAmountOut(Swap[] memory swap) external returns(uint256) {
        if (swap.length <= 1) {
			revert InvalidSwap();
		}

		if(treasury != address(0) && fee != 0) {
			uint256 swapFee = swap[0].amountIn * fee / 1_000_000;
			swap[0].amountIn -= swapFee;
		}

		uint256 lastAmountOut;
        for(uint256 i = 0; i < swap.length; i++) {
			if(i != 0) {
				swap[i].amountIn = lastAmountOut;
			}

		    if(swap[i].protocol == Protocol.UniswapV3) {
		    	lastAmountOut = _uniswapEstimateAmountOut(swap[i]);
		    } else if(swap[i].protocol == Protocol.SushiSwap) {
		    	lastAmountOut = _sushiswapEstimateAmountOut(swap[i]);
		    } else {
				lastAmountOut = swap[i].amountIn; // WETH -> ETH is 1 -> 1
			}
        }

		return lastAmountOut;
	}

	/** Internal Functions */

	function _uniswapSwap(Swap memory swap, address recipient) internal returns(uint256 amountOut) {
        return uniswapRouter.exactInputSingle(
			ISwapRouter.ExactInputSingleParams({
                tokenIn: swap.tokenA,
                tokenOut: swap.tokenB,
                fee: swap.poolFee,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: swap.amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
		);
	}

	function _sushiswapSwap(Swap memory swap, address recipient) internal returns(uint256 amountOut) {
		address[] memory path = new address[](2);
		path[0] = swap.tokenA;
		path[1] = swap.tokenB;

        sushiswapRouter.swapExactTokensForTokens(swap.amountIn, 0, path, recipient, block.timestamp);

		bool revertFlag;
		assembly {
			if iszero(eq(returndatasize(), 0x80)) {
				revertFlag := 1
			}
		}
		if(revertFlag) revert SushiswapFail();

		assembly {
			returndatacopy(0x20, 0x60, 0x20) // Copy the `0x60-0x7f` bytes from the returndata (last amount out from the array) to the `0x20-0x3f` "scratch space" memory location
			amountOut := mload(0x20)	     // Copy the saved bytes into `amountOut`
		}
	}

	function _wethSwap(Swap memory swap, address recipient) internal returns(uint256 amountOut) {
		if(swap.tokenA == address(0)) {
			// ETH -> WETH
			if(swap.tokenB != address(weth)) {
				revert InvalidSwap();
			}

			weth.deposit{ value: swap.amountIn }();

			if(recipient != address(this)) {
				TransferHelper.safeTransfer(address(weth), recipient, swap.amountIn);
			}
		} else if(swap.tokenA == address(weth)) {
			// WETH -> ETH
			if(swap.tokenB != address(0)) {
				revert InvalidSwap();
			}

			weth.withdraw(swap.amountIn);

			if(recipient != address(this)) {
				TransferHelper.safeTransferETH(recipient, swap.amountIn);
			}
		} else {
			revert InvalidSwap();
		}
		return swap.amountIn;
	}

	function _uniswapEstimateAmountOut(Swap memory swap) internal returns(uint256) {
		(uint256 amountOut,,,) = uniswapQuoter.quoteExactInput(abi.encodePacked(swap.tokenA, swap.poolFee, swap.tokenB), swap.amountIn);
		return amountOut;
	}

	function _sushiswapEstimateAmountOut(Swap memory swap) internal view returns(uint256 amountOut) {
		address[] memory path = new address[](2);
		path[0] = swap.tokenA;
		path[1] = swap.tokenB;

		sushiswapRouter.getAmountsOut(swap.amountIn, path);

		bool revertFlag;
		assembly {
			if iszero(eq(returndatasize(), 0x80)) {
				revertFlag := 1
			}
		}
		if(revertFlag) revert SushiswapFail();

		assembly {
			returndatacopy(0x20, 0x60, 0x20) // Copy the `0x60-0x7f` bytes from the returndata (last address) to the `0x20-0x3f` "scratch space" memory location
			amountOut := mload(0x20)	     // Copy the saved bytes into `amountOut`
		}
	}

	function _isWethDeposit(Swap memory swap) internal pure returns(bool) {
		return swap.protocol == Protocol.WETH && swap.tokenA == address(0);
	}

	/** Owner Only Functions */

	function approveRouters(address[] calldata tokens) external onlyOwner {
		for(uint256 i = 0; i < tokens.length; i++) {
			TransferHelper.safeApprove(tokens[i], address(uniswapRouter), type(uint256).max);
			TransferHelper.safeApprove(tokens[i], address(sushiswapRouter), type(uint256).max);
		}
	}

	function rescueToken(address token, uint256 value) external onlyOwner {
		TransferHelper.safeTransfer(token, msg.sender, value);
	}

	function rescueETH(uint256 value) external onlyOwner {
		TransferHelper.safeTransferETH(msg.sender, value);
	}

	function setFee(uint256 _fee) external onlyOwner {
		if(_fee > 100_000) {
			revert FeeTooHigh();
		}
		fee = _fee;
	}

	function setTreasury(address _treasury) external onlyOwner {
		treasury = _treasury;
	}

	/** Receive */

	receive() external payable duringLock {}
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoterV2 {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountIn The desired input amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountOut The desired output amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params)
        external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import { IUniswapV2Router02 } from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import { IQuoterV2 } from '@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol';
import { ISwapRouter } from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import { IWETH9 } from './IWETH9.sol';

interface IBatchSwap {
	/** Errors */
	error InsufficientAmountOut();
	error InvalidSwap();
	error SushiswapFail();
	error FeeTooHigh();
	error Locked();
	error NotLocked();

	/** Data Types */

	enum Protocol { UniswapV3, SushiSwap, WETH }

	enum Lock { __, UNLOCKED, LOCKED }

	struct Swap {
		Protocol protocol;
		address tokenA;
		address tokenB;
		uint24 poolFee;    // Only for UniswapV3
		uint256 amountIn;  // Only for first swap
	}

	/** Immutables */

	function uniswapRouter() external view returns(ISwapRouter);
	function uniswapQuoter() external view returns(IQuoterV2);
	function sushiswapRouter() external view returns(IUniswapV2Router02);
	function weth() external view returns(IWETH9);

	/** Storage */

	function treasury() external view returns(address);
	function fee() external view returns(uint256);

	/** External Functions */

    function singleSwap(Swap memory swap, uint256 minAmountOut, address recipient) external payable;
    function batchSwap(Swap[] memory swap, uint256 minAmountOut, address recipient) external payable;

	/** View Functions */

    function singleSwapEstimateAmountOut(Swap memory swap) external view returns(uint256);
    function batchSwapEstimateAmountOut(Swap[] memory swap) external view returns(uint256);

	/** Owner Only Functions */

	function approveRouters(address[] calldata tokens) external;
	function rescueToken(address token, uint256 value) external;
	function rescueETH(uint256 value) external;
	function setFee(uint256 _fee) external;
	function setTreasury(address _treasury) external;

	/** Receive */

	receive() external payable;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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