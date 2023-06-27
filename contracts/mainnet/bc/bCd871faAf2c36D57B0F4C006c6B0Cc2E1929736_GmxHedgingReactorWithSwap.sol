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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "prb-math/contracts/PRBMathUD60x18.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "../PriceFeed.sol";

import "../libraries/AccessControl.sol";
import "../libraries/OptionsCompute.sol";
import "../libraries/SafeTransferLib.sol";

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IHedgingReactor.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IPositionRouter.sol";
import "../interfaces/IReader.sol";
import "../interfaces/IGmxVault.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 *  @title A hedging reactor that will manage delta by opening or closing short or long perp positions using GMX
 *  @dev interacts with LiquidityPool via hedgeDelta, getDelta, getPoolDenominatedValue and withdraw,
 *       interacts with GMX via _increasePosition and _decreasePosition
 */

contract GmxHedgingReactorWithSwap is IHedgingReactor, AccessControl {
	using PRBMathSD59x18 for int256;
	using PRBMathUD60x18 for uint256;
	/////////////////////////////////
	/// immutable state variables ///
	/////////////////////////////////

	/// @notice address of the parent liquidity pool contract
	address public immutable parentLiquidityPool;
	/// @notice collateralAsset in the main Rysk protocol (native USDC)
	address public immutable collateralAsset;
	/// @notice address of the bridged version of USDC
	address public immutable bridgedCollateralAsset = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
	/// @notice address of the wETH contract
	address public immutable wETH;
	/// @notice the gmx vault contract address
	IGmxVault public immutable vault;
	/// @notice instance of the uniswap V3 router interface
	ISwapRouter public immutable swapRouter;

	/////////////////////////
	/// dynamic variables ///
	/////////////////////////

	/// @notice delta of the pool
	int256 public internalDelta;
	/// @notice magnitude of delta held in open shorts
	uint public openShortDelta;
	/// @notice magnitude of delta held in open longs
	uint public openLongDelta;
	uint8 public pendingIncreaseCallback;
	uint8 public pendingDecreaseCallback;
	mapping(bytes32 => int256) public increaseOrderDeltaChange;
	mapping(bytes32 => int256) public decreaseOrderDeltaChange;
	mapping(bytes32 => bool) public pendingIncreaseOrders;
	mapping(bytes32 => bool) public pendingDecreaseOrders;
	/// @notice value of any tokens that have been sent to GMX contract for positions that have not been executed/cancelled yet
	uint public pendingIncreaseCollateralValue;
	/// @notice indicates whether we have a long position open at the same time as a short
	bool public longAndShortOpen;

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	/// @notice address of the keeper of this pool
	mapping(address => bool) public keeper;
	/// @notice desired healthFactor of the pool
	uint256 public healthFactor = 5_000;
	/// @notice price deviation tolerance for collateral swapping
	uint256 public collateralSwapPriceTolerance = 5e15; // 0.5%
	/// @notice price tolerance for opening/closing positions
	uint256 public positionPriceTolerance = 5e15; // 0.5%
	/// @notice tolerance on collateral to remove on full closures
	int256 public collateralRemovalPercentage = 9900; // 99%
	/// @notice address of the price feed used for getting asset prices
	address public priceFeed;
	/// @notice the GMX position router contract
	IPositionRouter public gmxPositionRouter;
	/// @notice the GMX Router contract
	IRouter public router;
	/// @notice the GMX Reader contract
	IReader public reader;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	/// @notice used for unlimited token approval
	uint256 private constant MAX_UINT = 2 ** 256 - 1;
	/// @notice max bips
	uint256 private constant MAX_BIPS = 10_000;
	/// @notice divisor for 10% buffer denominated in bips
	uint private constant BUFFER = 11_000;
	/// @notice for converting from GMX's e30 notation to e18
	uint private constant GMX_DECIMAL_CONVERT = 1e12;
	/// @notice conversion from GMX e30 to collateral decimals
	uint private constant GMX_TO_COLLATERAL_DECIMALS = 1e24;
	/// @notice number of decimals on the collateralAsset ERC20 contract
	uint8 private constant COLLATERAL_ASSET_DECIMALS = 6;

	//////////////
	/// events ///
	//////////////

	event CreateIncreasePosition(bytes32 positionKey);
	event CreateDecreasePosition(bytes32 positionKey);
	event RebalancePortfolioDeltaFailed(int256 delta);
	event PositionExecuted(int256 deltaChange);

	constructor(
		address _gmxPositionRouter,
		address _gmxRouter,
		address _gmxReader,
		address _gmxVault,
		address _collateralAsset,
		address _wethAddress,
		address _parentLiquidityPool,
		address _priceFeed,
		address _authority,
		address _swapRouter
	) AccessControl(IAuthority(_authority)) {
		router = IRouter(_gmxRouter);
		reader = IReader(_gmxReader);
		vault = IGmxVault(_gmxVault);
		gmxPositionRouter = IPositionRouter(_gmxPositionRouter);
		router.approvePlugin(_gmxPositionRouter);
		parentLiquidityPool = _parentLiquidityPool;
		wETH = _wethAddress;
		collateralAsset = _collateralAsset;
		priceFeed = _priceFeed;
		swapRouter = ISwapRouter(_swapRouter);
		SafeTransferLib.safeApprove(ERC20(_collateralAsset), address(swapRouter), MAX_UINT);
		SafeTransferLib.safeApprove(ERC20(bridgedCollateralAsset), address(swapRouter), MAX_UINT);
	}

	receive() external payable {}

	///////////////
	/// setters ///
	///////////////

	/// @notice update the health factor parameter
	function setHealthFactor(uint256 _healthFactor) external {
		_onlyGovernor();
		healthFactor = _healthFactor;
	}

	/// @notice update the keepers
	function setKeeper(address _keeper, bool _auth) external {
		_onlyGovernor();
		keeper[_keeper] = _auth;
	}

	function setPositionRouter(address _gmxPositionRouter) external {
		_onlyGovernor();
		if (pendingIncreaseCallback != 0 || pendingDecreaseCallback != 0) {
			revert CustomErrors.GmxCallbackPending();
		}
		router.denyPlugin(address(gmxPositionRouter));
		gmxPositionRouter = IPositionRouter(_gmxPositionRouter);
		router.approvePlugin(_gmxPositionRouter);
	}

	function setReader(address _reader) external {
		_onlyGovernor();
		reader = IReader(_reader);
	}

	function setRouter(address _router) external {
		_onlyGovernor();
		router = IRouter(_router);
	}

	function setPriceFeed(address _priceFeed) external {
		_onlyGovernor();
		priceFeed = _priceFeed;
	}

	function setCollateralSwapPriceTolerance(uint256 _collateralSwapPriceTolerance) external {
		_onlyGovernor();
		collateralSwapPriceTolerance = _collateralSwapPriceTolerance;
	}

	function setPositionPriceTolerance(uint256 _positionPriceTolerance) external {
		_onlyGovernor();
		positionPriceTolerance = _positionPriceTolerance;
	}

	function setCollateralRemovalPercentage(int256 _collateralRemovalPercentage) external {
		_onlyGovernor();
		collateralRemovalPercentage = _collateralRemovalPercentage;
	}

	function resetPendingPositionCallbacks() external {
		_onlyGovernor();
		pendingIncreaseCallback = 0;
		pendingDecreaseCallback = 0;
	}

	////////////////////////////////////////////
	/// access-controlled external functions ///
	////////////////////////////////////////////

	function sweepFunds(uint256 _amount, address _receiver) external {
		_onlyGovernor();
		uint256 balance = address(this).balance;
		SafeTransferLib.safeTransferETH(_receiver, _amount > balance ? balance : _amount);
	}

	/// @inheritdoc IHedgingReactor
	function hedgeDelta(int256 _delta) external returns (int256 deltaChange) {
		require(_delta != 0, "delta change is zero");
		if (pendingIncreaseCallback != 0 || pendingDecreaseCallback != 0) {
			revert CustomErrors.GmxCallbackPending();
		}

		// delta is passed in as the delta that the pool has so this function must hedge the opposite
		// if delta comes in negative then the pool must go long
		// if delta comes in positive then the pool must go short
		// the signs must be flipped when going into _changePosition
		// make sure the caller is the vault
		require(msg.sender == parentLiquidityPool, "!vault");
		sync();
		_changePosition(-_delta);
		return 0;
	}

	/// @inheritdoc IHedgingReactor
	function withdraw(uint256 _amount) external returns (uint256) {
		require(msg.sender == parentLiquidityPool, "!vault");
		// this is likely due to the liquidity pool removing this reactor
		// so ensure no pending positions first
		if (_amount == type(uint256).max) {
			if (pendingIncreaseCallback != 0 || pendingDecreaseCallback != 0) {
				revert CustomErrors.GmxCallbackPending();
			}
		}
		// check the holdings if enough just lying around then transfer it
		// assume amount is passed in as collateral decimals
		uint256 balance = ERC20(bridgedCollateralAsset).balanceOf(address(this));
		if (balance == 0) {
			return 0;
		}
		if (_amount <= balance) {
			_transferOut(_amount);
			// return in collateral format
			return _amount;
		} else {
			_transferOut(balance);
			// return in collateral format
			return balance;
		}
	}

	/// @notice function to re-calibrate internalDelta in case of liquidation
	function sync() public returns (int256) {
		_isKeeper();
		(int _internalDelta, uint _longDelta, uint _shortDelta) = _getLiveDelta();
		openLongDelta = _longDelta;
		openShortDelta = _shortDelta;
		internalDelta = _internalDelta;
		return _internalDelta;
	}

	function _getLiveDelta() internal view returns (int256, uint, uint) {
		uint256[] memory longPosition = _getPosition(true);
		uint256[] memory shortPosition = _getPosition(false);
		uint256 longDelta = longPosition[0] > 0 ? (longPosition[0]).div(longPosition[2]) : 0;
		uint256 shortDelta = shortPosition[0] > 0 ? (shortPosition[0]).div(shortPosition[2]) : 0;
		return (int256(longDelta) - int256(shortDelta), longDelta, shortDelta);
	}

	/// @inheritdoc IHedgingReactor
	function update() external returns (uint256) {

		_isKeeper();
		int _internalDelta = sync();
		if (_internalDelta == 0 && openLongDelta == 0 && openShortDelta == 0) {
			revert CustomErrors.NoPositionsOpen();
		}
		if (pendingIncreaseCallback != 0 || pendingDecreaseCallback != 0) {
			revert CustomErrors.GmxCallbackPending();
		}
		(
			bool isBelowMin,
			bool isAboveMax,
			,
			uint256 collatToTransfer,
			uint256[] memory position,
			bool bothPositionsOpen
		) = checkVaultHealth();
		if (bothPositionsOpen) {
			// need to consolidate positions
			uint collateralToRemoveLong;
			uint collateralToRemoveShort;
			if (_internalDelta >= 0) {
				// we are net long/neutral. close shorts
				uint256[] memory shortPosition = _getPosition(false);
				collateralToRemoveShort = _getCollateralSizeDeltaUsd(false, false, openShortDelta, false);
				(bytes32 key1, int deltaChange1) = _decreasePosition(
					openShortDelta,
					collateralToRemoveShort,
					false
				);
				decreaseOrderDeltaChange[key1] += deltaChange1;
				// then reduce longs by same delta
				collateralToRemoveLong = _getCollateralSizeDeltaUsd(false, false, openShortDelta, true);
				(bytes32 key2, int deltaChange2) = _decreasePosition(
					openShortDelta,
					collateralToRemoveLong,
					true
				);
				decreaseOrderDeltaChange[key2] += deltaChange2;
			} else {
				// we are net short
				uint256[] memory longPosition = _getPosition(true);
				collateralToRemoveLong = _getCollateralSizeDeltaUsd(false, false, openLongDelta, true);
				(bytes32 key1, int deltaChange1) = _decreasePosition(
					openLongDelta,
					collateralToRemoveLong,
					true
				);
				decreaseOrderDeltaChange[key1] += deltaChange1;
				// then reduce shorts by same delta
				collateralToRemoveShort = _getCollateralSizeDeltaUsd(false, false, openLongDelta, false);
				(bytes32 key2, int deltaChange2) = _decreasePosition(
					openLongDelta,
					collateralToRemoveShort,
					false
				);
				decreaseOrderDeltaChange[key2] += deltaChange2;
			}
			return collateralToRemoveLong + collateralToRemoveShort;
		}
		if (isBelowMin) {
			// collateral needs adding to position
			_addCollateral(collatToTransfer, _internalDelta > 0);
			return collatToTransfer;
		} else if (isAboveMax) {
			// collateral needs removing
			// check if collateral removed would put position within 10% of liquidation limit
			// where positionSize / collateral is >= maxLeverage()
			if (
				// maxLeverage is multiplied by 10000 in contract. divide by 11000 to allow for 10% buffer.
				int256(position[1] / GMX_TO_COLLATERAL_DECIMALS) - int256(collatToTransfer) <
				int256((position[0] / GMX_TO_COLLATERAL_DECIMALS) / (vault.maxLeverage() / BUFFER))
			) {
				collatToTransfer =
					position[1] /
					GMX_TO_COLLATERAL_DECIMALS -
					(position[0] / GMX_TO_COLLATERAL_DECIMALS) /
					(vault.maxLeverage() / BUFFER);
				if (collatToTransfer == 0) {
					return 0;
				}
			}
			_removeCollateral(collatToTransfer, _internalDelta > 0);
			return collatToTransfer;
		}
		return 0;
	}

	/**
	 *	@notice internal function called by update() to add more collateral to the perp position
	 *	@param _collateralAmount amount of collateral tokens to add. Denominated in e6
	 *	@param _isLong whether the perp position is long or short
	 **/
	function _addCollateral(
		uint256 _collateralAmount,
		bool _isLong
	) internal returns (bytes32 positionKey, int256 deltaChange) {
		return _increasePosition(0, _collateralAmount, _isLong);
	}

	/**
	 *	@notice internal function called by update() to removing collateral from the perp position
	 *	@param _collateralAmount amount of collateral tokens to add. Denominated in e6
	 *	@param _isLong whether the perp position is long or short
	 **/
	function _removeCollateral(
		uint256 _collateralAmount,
		bool _isLong
	) internal returns (bytes32 positionKey, int256 deltaChange) {
		return _decreasePosition(0, _collateralAmount, _isLong);
	}

	///////////////////////
	/// complex getters ///
	///////////////////////

	/// @inheritdoc IHedgingReactor
	function getDelta() external view returns (int256) {
		(int _internalDelta, , ) = _getLiveDelta();
		return _internalDelta;
	}

	/// @inheritdoc IHedgingReactor
	function getPoolDenominatedValue() external view returns (uint256 value) {
		(int _internalDelta, , ) = _getLiveDelta();
		uint256[] memory position = _getPosition(_internalDelta > 0);
		if (position[7] == 1) {
			value = (position[1] + position[8]) / GMX_DECIMAL_CONVERT;
		} else {
			value = (position[1] - position[8]) / GMX_DECIMAL_CONVERT;
		}
		value += OptionsCompute.convertFromDecimals(
			ERC20(bridgedCollateralAsset).balanceOf(address(this)),
			COLLATERAL_ASSET_DECIMALS
		);
		if (pendingIncreaseCallback != 0) {
			value += OptionsCompute.convertFromDecimals(
				pendingIncreaseCollateralValue,
				COLLATERAL_ASSET_DECIMALS
			);
		}
		if (longAndShortOpen) {
			// we have a position open on the opposite side to the one above, so add that to value
			uint256[] memory otherPosition = _getPosition(_internalDelta <= 0);
			if (otherPosition[7] == 1) {
				value += (otherPosition[1] + otherPosition[8]) / GMX_DECIMAL_CONVERT;
			} else {
				value += (otherPosition[1] - otherPosition[8]) / GMX_DECIMAL_CONVERT;
			}
		}
	}

	/** @notice function to check the health of the margin account
	 *  @return isBelowMin is the margin below the health factor
	 *  @return isAboveMax is the margin above the health factor
	 *  @return health     the health factor of the account currently
	 *  @return collatToTransfer the amount of collateral required to return the margin account back to the health factor. e6
	 */
	function checkVaultHealth()
		public
		view
		returns (
			bool isBelowMin,
			bool isAboveMax,
			int256 health,
			uint256 collatToTransfer,
			uint256[] memory position,
			bool
		)
	{
		(int _internalDelta, , ) = _getLiveDelta();
		position = _getPosition(_internalDelta > 0);
		// position[0] = position size in USD
		// position[1] = collateral amount in USD
		// position[2] = average entry price of position
		// position[3] = entry funding rate
		// position[4] = does position have *realised* profit
		// position[5] = realised PnL
		// position[6] = timestamp of last position increase
		// position[7] = is position in profit
		// position[8] = current unrealised Pnl
		// HF = (collatSize + unrealised pnl) / positionSize

		if (position[0] == 0) {
			//no positions open
			return (false, false, int256(healthFactor), 0, position, longAndShortOpen);
		}
		if (position[7] == 1) {
			//position in profit
			health = int256(((position[1] + position[8]).div(position[0]) * MAX_BIPS) / 1e18);
		} else {
			//position in loss
			health =
				((int256(position[1]) - int256(position[8])).div(int256(position[0])) * int256(MAX_BIPS)) /
				1e18;
		}
		if (health > int256(healthFactor)) {
			// position is over-collateralised
			isAboveMax = true;
			isBelowMin = false;
			// health must be > 0 so can cast to uint
			collatToTransfer =
				((uint256(health) - healthFactor) * position[0]) /
				MAX_BIPS /
				GMX_TO_COLLATERAL_DECIMALS;
		} else if (health < int256(healthFactor)) {
			// position undercollateralised
			// more collateral needs adding
			isBelowMin = true;
			isAboveMax = false;
			collatToTransfer = uint256(
				((int256(healthFactor) - health) * int256(position[0])) /
					int256(MAX_BIPS) /
					int(GMX_TO_COLLATERAL_DECIMALS)
			);
		} else {
			// health factor is perfect
			return (false, false, health, 0, position, longAndShortOpen);
		}
		return (isBelowMin, isAboveMax, health, collatToTransfer, position, longAndShortOpen);
	}

	//////////////////////////
	/// internal utilities ///
	//////////////////////////

	/** @notice function to handle logic of when to open and close positions
	 *	GMX handles shorts and longs separately, so we only want to have either a short OR a long open
	 *	at any one time to aavoid paying borrow fees both ways.
	 *	This function will close off any shorts before opening longs and vice versa.
	 *  @param _amount the amount of delta to change exposure by. e18
	 */
	function _changePosition(int256 _amount) internal {
		bool closedOppositeSideFirst = false;
		int256 closedPositionDeltaChange;
		if (_amount > 0) {
			// enter long position
			bytes32 positionKey;
			int256 deltaChange;
			if (internalDelta < 0) {
				// close short position before opening long
				uint256 adjustedPositionSize = _adjustedReducePositionSize(uint256(_amount), false);
				uint256 collateralToRemove = _getCollateralSizeDeltaUsd(
					false,
					false,
					adjustedPositionSize,
					false
				);
				(positionKey, deltaChange) = _decreasePosition(adjustedPositionSize, collateralToRemove, false);
				// update deltaChange for callback function
				decreaseOrderDeltaChange[positionKey] += deltaChange;

				// remove the adjustedPositionSize from _amount to get remaining amount of delta to hedge to open shorts with
				_amount = _amount - int256(adjustedPositionSize);
				if (_amount == 0) return;
				closedPositionDeltaChange = deltaChange;
				closedOppositeSideFirst = true;
			}

			uint256 collateralToAdd = _getCollateralSizeDeltaUsd(
				true,
				closedOppositeSideFirst,
				uint256(_amount),
				true
			);

			(positionKey, deltaChange) = _increasePosition(uint256(_amount), collateralToAdd, true);
			// update deltaChange for callback function
			increaseOrderDeltaChange[positionKey] += deltaChange;
		} else {
			// _amount is negative
			// enter a short position
			bytes32 positionKey;
			int256 deltaChange;
			if (internalDelta > 0) {
				// close longs first
				uint256 adjustedPositionSize = _adjustedReducePositionSize(uint256(-_amount), true);
				uint256 collateralToRemove = _getCollateralSizeDeltaUsd(
					false,
					false,
					adjustedPositionSize,
					true
				);
				(positionKey, deltaChange) = _decreasePosition(adjustedPositionSize, collateralToRemove, true);
				// update deltaChange for callback function
				decreaseOrderDeltaChange[positionKey] += deltaChange;
				// remove the adjustedPositionSize from _amount to get remaining amount of delta to hedge to open shorts with
				_amount = _amount + int256(adjustedPositionSize); // _amount is negative so addition needed
				if (_amount == 0) return;
				closedPositionDeltaChange = deltaChange;
				closedOppositeSideFirst = true;
			}
			// increase short position
			uint256 collateralToAdd = _getCollateralSizeDeltaUsd(
				true,
				closedOppositeSideFirst,
				uint256(-_amount),
				false
			);
			(positionKey, deltaChange) = _increasePosition(uint256(-_amount), collateralToAdd, false);
			// update deltaChange for callback function
			increaseOrderDeltaChange[positionKey] += deltaChange;
		}
	}

	/**
	 *	@notice internal function to handle increasing position size on GMX
	 *	@param _size ETH denominated size to increase position by. e18
	 *	@param _collateralSize amount of collateral to add. denominated in collateralAsset decimals.
	 *	@param _isLong whether the position is a long or short
	 *	@return positionKey the unique key of the GMX position
	 *	@return deltaChange the resulting delta change from the position increase
	 */
	function _increasePosition(
		uint256 _size,
		uint256 _collateralSize,
		bool _isLong
	) internal returns (bytes32 positionKey, int256 deltaChange) {
		if (pendingIncreaseCallback != 0) {
			revert CustomErrors.GmxCallbackPending();
		}
		uint256 currentPrice = getUnderlyingPrice(wETH, bridgedCollateralAsset);

		// take that amount of collateral from the Liquidity Pool and approve to GMX
		if (_collateralSize > 0) {
			_transferIn(_collateralSize);
			SafeTransferLib.safeApprove(ERC20(bridgedCollateralAsset), address(router), _collateralSize);
		}

		positionKey = gmxPositionRouter.createIncreasePosition{
			value: gmxPositionRouter.minExecutionFee()
		}(
			_createPathIncreasePosition(_isLong),
			wETH,
			_collateralSize,
			_isLong
				? (_collateralSize * GMX_DECIMAL_CONVERT).mul(1e18 - collateralSwapPriceTolerance).div(
					currentPrice
				)
				: 0,
			_size.mul(currentPrice) * GMX_DECIMAL_CONVERT,
			_isLong,
			_isLong
				? currentPrice.mul(1e18 + positionPriceTolerance) * GMX_DECIMAL_CONVERT
				: currentPrice.mul(1e18 - positionPriceTolerance) * GMX_DECIMAL_CONVERT,
			gmxPositionRouter.minExecutionFee(),
			"leverageisfun",
			address(this)
		);
		emit CreateIncreasePosition(positionKey);
		pendingIncreaseCallback++;
		pendingIncreaseCollateralValue = _collateralSize;
		pendingIncreaseOrders[positionKey] = true;

		return (positionKey, _isLong ? int256(_size) : -int256(_size));
	}

	/**
	 *	@notice internal function to handle decreasing position size on GMX
	 *	@param _size ETH denominated size to decrease position by. e18
	 *	@param _collateralSize amount of collateral to remove. denominated in collateralAsset decimals.
	 *	@param _isLong whether the position is a long or short
	 *	@return positionKey the unique key of the GMX position
	 *	@return deltaChange the resulting delta change from the position decrease
	 */
	function _decreasePosition(
		uint256 _size,
		uint256 _collateralSize,
		bool _isLong
	) internal returns (bytes32 positionKey, int256 deltaChange) {
		uint256[] memory position = _getPosition(_isLong);
		uint256 currentPrice = getUnderlyingPrice(wETH, bridgedCollateralAsset);

		// calculate change in dollar value of position
		// equal to (_size / abs(internalDelta)) * positionSize
		// expressed in e30 decimals
		uint256 positionSizeDeltaUsd = _getPositionSizeDeltaUsd(_size, position[0], _isLong);
		positionKey = gmxPositionRouter.createDecreasePosition{
			value: gmxPositionRouter.minExecutionFee()
		}(
			_createPathDecreasePosition(_isLong),
			wETH,
			_collateralSize * GMX_TO_COLLATERAL_DECIMALS,
			positionSizeDeltaUsd,
			_isLong,
			address(this),
			_isLong
				? currentPrice.mul(1e18 - positionPriceTolerance) * GMX_DECIMAL_CONVERT
				: currentPrice.mul(1e18 + positionPriceTolerance) * GMX_DECIMAL_CONVERT, // mul by 0.995 e12 for slippage
			0,
			gmxPositionRouter.minExecutionFee(),
			false,
			address(this)
		);
		emit CreateDecreasePosition(positionKey);
		pendingDecreaseCallback++;
		pendingDecreaseOrders[positionKey] = true;
		return (positionKey, _isLong ? -int256(_size) : int256(_size));
	}

	/**
	 *	@notice gets current position details from GMX reader contract
	 *	@param _isLong if the position to get details for is a long position
	 *	@return position an array of figures describing the state of the position
	 */
	function _getPosition(bool _isLong) private view returns (uint256[] memory position) {
		address[] memory indexToken = new address[](1);

		indexToken[0] = wETH;
		address[] memory collateralToken = new address[](1);
		bool[] memory isLong = new bool[](1);
		if (!_isLong) {
			// get short pos
			collateralToken[0] = bridgedCollateralAsset;
			isLong[0] = false;
		} else {
			// get long pos
			collateralToken[0] = wETH;
			isLong[0] = true;
		}
		position = reader.getPositions(
			address(vault),
			address(this),
			collateralToken,
			indexToken,
			isLong
		);
	}

	/**
	 *	@notice a function that floors a reduce position sizeDelta to only be as big as the open position itself
	 *	@param _size number of deltas to decrease position by
	 *  @param _isLong whether the position is a long
	 *	@return adjustedSize the floored number of deltas to decrease position by
	 */
	function _adjustedReducePositionSize(
		uint256 _size,
		bool _isLong
	) private view returns (uint256 adjustedSize) {
		if (_isLong) {
			return openLongDelta > _size ? _size : openLongDelta;
		} else {
			return openShortDelta > _size ? _size : openShortDelta;
		}
	}

	/**
	 *	@param _isLong if the position to be changed is long
	 *	@return path the _path array formatted for the GMX contract call
	 */
	function _createPathIncreasePosition(bool _isLong) internal view returns (address[] memory) {
		if (_isLong) {
			address[] memory path = new address[](2);
			path[0] = bridgedCollateralAsset;
			path[1] = wETH;
			return path;
		} else {
			address[] memory path = new address[](1);
			path[0] = bridgedCollateralAsset;
			return path;
		}
	}

	/**
	 *	@param _isLong if the position to be changed is long
	 *	@return path the _path array formatted for the GMX contract call
	 */
	function _createPathDecreasePosition(bool _isLong) internal view returns (address[] memory) {
		if (_isLong) {
			address[] memory path = new address[](2);
			path[0] = wETH;
			path[1] = bridgedCollateralAsset;
			return path;
		} else {
			address[] memory path = new address[](1);
			path[0] = bridgedCollateralAsset;
			return path;
		}
	}

	/**
	 *	@param _isIncreasePosition if the position is to be increased (or decreased)
	 *	@param _closedOppositeSideFirst in the case of an increase, true if an opposite position has been closed in the same transaction
	 *	@param _amount amount of deltas to change position by. e18
	 *  @param _isLong whether the position is a long one, false if short.
	 *	@return amount of collateral to add (for increase) or remove (for decrease). denominated in e6
	 */
	function _getCollateralSizeDeltaUsd(
		bool _isIncreasePosition,
		bool _closedOppositeSideFirst,
		uint256 _amount,
		bool _isLong
	) private view returns (uint256) {
		// calculate amount of collateral to add or remove denominated in USDC
		//  for increase positions this is equal to collateral needed for extra margin plus rebalancing collateral to bring health factor back to 5000
		if (_isIncreasePosition) {
			if (_closedOppositeSideFirst) {
				// this is a new position so no pnl to account for
				return
					OptionsCompute.convertToDecimals(
						(_amount.mul(getUnderlyingPrice(wETH, bridgedCollateralAsset)) * healthFactor) / MAX_BIPS,
						COLLATERAL_ASSET_DECIMALS
					);
			}
			(, bool isAboveMax, , uint256 collatToTransfer, , ) = checkVaultHealth();
			// this is the collateral needed to increase position with no health factor rebalancing
			uint256 extraPositionCollateral = OptionsCompute.convertToDecimals(
				(_amount.mul(getUnderlyingPrice(wETH, bridgedCollateralAsset)) * healthFactor) / MAX_BIPS,
				COLLATERAL_ASSET_DECIMALS
			);
			uint256 totalCollateralToAdd;
			if (isAboveMax && collatToTransfer > extraPositionCollateral) {
				// in this case there is a net collateral withdrawal needed which cannot be done with increasePosition
				// so just dont add any more collateral and have it rebalance later
				totalCollateralToAdd = 0;
			} else {
				// otherwise add the two collateral requirement parts to obtain total collateral input
				if (isAboveMax) {
					// take away excess collateral
					totalCollateralToAdd = extraPositionCollateral - collatToTransfer;
				} else {
					// add extra needed collateral
					totalCollateralToAdd = extraPositionCollateral + collatToTransfer;
				}
			}
			uint256[] memory position = _getPosition(_isLong);
			// check if collateral removed would put position within 10% of liquidation limit
			// where positionSize / collateral is >= maxLeverage()
			// maxLeverage is multiplied by 10000 in contract. divide by 11000 to allow for 10% buffer.
			uint256 minAllowedCollateral = OptionsCompute.convertToDecimals(
				(
					(position[0] /
						GMX_DECIMAL_CONVERT +
						_amount.mul(getUnderlyingPrice(wETH, bridgedCollateralAsset)))
				) / (vault.maxLeverage() / BUFFER),
				COLLATERAL_ASSET_DECIMALS
			);
			if (
				OptionsCompute.convertToDecimals(position[1] / GMX_DECIMAL_CONVERT, COLLATERAL_ASSET_DECIMALS) +
					totalCollateralToAdd <
				minAllowedCollateral
			) {
				// position[1] cannot be bigger than minAllowedCollateral here - no underflow
				totalCollateralToAdd =
					minAllowedCollateral -
					OptionsCompute.convertToDecimals(position[1] / GMX_DECIMAL_CONVERT, COLLATERAL_ASSET_DECIMALS);
			}
			return totalCollateralToAdd;
		} else {
			uint256 leverageFactor = MAX_BIPS.div(healthFactor);
			// when decreasing a position, a proportion of the pnl (positive or negative) equal to the proportion of the
			// position size being reduced is taken out of the position.
			uint256[] memory position = _getPosition(_isLong);
			// position[0] = position size in USD
			// position[1] = collateral amount in USD
			// position[2] = average entry price of position
			// position[3] = entry funding rate
			// position[4] = does position have *realised* profit
			// position[5] = realised PnL
			// position[6] = timestamp of last position increase
			// position[7] = is position in profit
			// position[8] = current unrealised Pnl

			int256 collateralToRemove;
			if (position[7] == 1) {
				// position in profit
				// with positions in profit, you receive collateral out equal to the value entered for _collateralDelta in the createDecreasePosition
				// function PLUS the proportion of the pnl equal to proportion of position size being reduced.
				{
					collateralToRemove = (1e18 -
						(
							(int256(position[0] / GMX_DECIMAL_CONVERT) -
								int256((leverageFactor.mul(position[8])) / GMX_DECIMAL_CONVERT))
								.mul(1e18 - int256(_amount.mul(position[2]).div(position[0])))
								.div(int256(leverageFactor.mul(position[1]) / GMX_DECIMAL_CONVERT))
						)).mul(int256(position[1] / GMX_DECIMAL_CONVERT));
				}
			} else {
				// position in loss
				// with positions in loss, what is entered into the createDecreasePosition function is what you receive
				// however the pnl is still reduced proportionally
				// we need to make sure that adjustedAmount can never be greater than position[0].div(position[2]) which is the actual size of position the dhv has
				uint256 adjustedAmount = _amount < position[0].div(position[2])
					? _amount
					: position[0].div(position[2]);
				uint256 d = adjustedAmount.mul(position[2]).div(position[0]);
				{
					// we need to adjust the collateral to remove by 1% to account for oracle price changes between this call and the gmx callback
					collateralToRemove =
						(((int256(position[1] / GMX_DECIMAL_CONVERT) -
							(
								(int256(position[0] / GMX_DECIMAL_CONVERT)).mul(1e18 - int256(d)).div(
									int256(leverageFactor)
								)
							)) - int256(position[8] / GMX_DECIMAL_CONVERT)) * collateralRemovalPercentage) /
						10000;
				}
			}
			uint256 adjustedCollateralToRemove;
			// collateral to remove must be a uint
			if (collateralToRemove < 0) {
				adjustedCollateralToRemove = uint256(0);
			} else {
				adjustedCollateralToRemove = uint256(collateralToRemove);

				// check if collateral removed would put position within 10% of liquidation limit
				// where positionSize / collateral is >= maxLeverage()
				uint256 minAllowedCollateral = ((position[0] -
					_getPositionSizeDeltaUsd(_amount, position[0], _isLong)) / GMX_DECIMAL_CONVERT) /
					(vault.maxLeverage() / BUFFER);
				if (
					// maxLeverage is multiplied by 10000 in contract. divide by 11000 to allow for 10% buffer.
					int256(position[1] / GMX_DECIMAL_CONVERT) - int256(adjustedCollateralToRemove) <
					int256(minAllowedCollateral)
				) {
					adjustedCollateralToRemove = position[1] / GMX_DECIMAL_CONVERT - minAllowedCollateral;
					if (adjustedCollateralToRemove == 0) {
						return 0;
					}
				}
			}
			return OptionsCompute.convertToDecimals(adjustedCollateralToRemove, COLLATERAL_ASSET_DECIMALS);
		}
	}

	/**	@notice GMX position size remains fixed through price fluctuations and is denominated in USD.
							This function converts from ETH denominated delta to USD denominated position size change
	 *	@param _size amount of deltas to change position by. e18
	 *	@param positionSize USD size of existing position as given by GMX. e30
	 *	@return USD size to change position by. e30
	 */
	function _getPositionSizeDeltaUsd(
		uint256 _size,
		uint256 positionSize,
		bool _isLong
	) private view returns (uint256) {
		return _size.mul(positionSize).div(_isLong ? openLongDelta : openShortDelta);
	}

	// ---- functions to force execution in case of GMX keeper failure
	function executeIncreasePosition(bytes32 positionKey) external {
		try gmxPositionRouter.executeIncreasePosition(positionKey, payable(address(this))) {} catch {
			try gmxPositionRouter.cancelIncreasePosition(positionKey, payable(address(this))) {} catch {}
		}
	}

	function executeDecreasePosition(bytes32 positionKey) external {
		try gmxPositionRouter.executeDecreasePosition(positionKey, payable(address(this))) {} catch {
			try gmxPositionRouter.cancelDecreasePosition(positionKey, payable(address(this))) {} catch {}
		}
	}

	/**	@notice function which will be called by a GMX keeper when they execute or reject our position request
	 *	@param positionKey unique key of the position request given by GMX
	 *	@param isExecuted if the position change was executed successfully
	 *	@param isIncrease if the position was increased
	 */
	function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external {
		if (msg.sender != address(gmxPositionRouter)) {
			revert CustomErrors.InvalidGmxCallback();
		}
		if (isExecuted) {

			if (isIncrease && pendingIncreaseOrders[positionKey]) {
				int deltaChange = increaseOrderDeltaChange[positionKey];
				internalDelta += deltaChange;
				if (deltaChange > 0) {
					// increase position results in positive delta change => must be a long
					openLongDelta += uint(deltaChange);
					if (openShortDelta > 0) {
						longAndShortOpen = true;
					}
				}
				if (deltaChange < 0) {
					// increase position results in negative delta change => must be a short
					openShortDelta += uint(-deltaChange);
					if (openLongDelta > 0) {
						longAndShortOpen = true;
					}
				}
				pendingIncreaseCallback--;
				delete increaseOrderDeltaChange[positionKey];
				delete pendingIncreaseOrders[positionKey];
				delete pendingIncreaseCollateralValue;
				emit PositionExecuted(deltaChange);
			} else if (!isIncrease && pendingDecreaseOrders[positionKey]) {
				int deltaChange = decreaseOrderDeltaChange[positionKey];
				internalDelta += deltaChange;
				if (deltaChange > 0) {
					// decrease position results in positive delta change => must be a short
					openShortDelta -= uint(deltaChange);
					if (openShortDelta == 0) {
						longAndShortOpen = false;
					}
				}
				if (deltaChange < 0) {
					// decrease position results in negative delta change => must be a long
					openLongDelta -= uint(-deltaChange);
					if (openLongDelta == 0) {
						longAndShortOpen = false;
					}
				}
				pendingDecreaseCallback--;
				delete decreaseOrderDeltaChange[positionKey];
				delete pendingDecreaseOrders[positionKey];
				emit PositionExecuted(deltaChange);
			}
		} else {
			// if there was a failure record the failure by emitting an event
			if (isIncrease && pendingIncreaseOrders[positionKey]) {
				emit RebalancePortfolioDeltaFailed(increaseOrderDeltaChange[positionKey]);
				pendingIncreaseCallback--;
				delete increaseOrderDeltaChange[positionKey];
				delete pendingIncreaseOrders[positionKey];
				delete pendingIncreaseCollateralValue;
			} else if (!isIncrease && pendingDecreaseOrders[positionKey]) {
				emit RebalancePortfolioDeltaFailed(decreaseOrderDeltaChange[positionKey]);
				pendingDecreaseCallback--;
				delete decreaseOrderDeltaChange[positionKey];
				delete pendingDecreaseOrders[positionKey];
			}
		}
		// send any collateral back to the liquidity pool
		uint256 balance = ERC20(bridgedCollateralAsset).balanceOf(address(this));
		if (balance > 0) {
			_transferOut(balance);
		}
	}

	/**
	 * @notice get the underlying price with just the underlying asset and strike asset
	 * @param underlying   the asset that is used as the reference asset
	 * @param _strikeAsset the asset that the underlying value is denominated in
	 * @return the underlying price
	 */
	function getUnderlyingPrice(
		address underlying,
		address _strikeAsset
	) internal view returns (uint256) {
		return PriceFeed(priceFeed).getNormalizedRate(underlying, _strikeAsset);
	}

	function _transferIn(uint256 _amount) internal {
		uint256 _amountInMaximum = (_amount * 10050) / 10000;
		if (ILiquidityPool(parentLiquidityPool).getBalance(collateralAsset) < _amountInMaximum) {
			revert CustomErrors.WithdrawExceedsLiquidity();
		}
		// transfer funds from the liquidity pool here
		SafeTransferLib.safeTransferFrom(
			collateralAsset,
			parentLiquidityPool,
			address(this),
			_amountInMaximum
		);
		// convert from the native usdc to bridged usdc
		ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
			tokenIn: collateralAsset,
			tokenOut: bridgedCollateralAsset,
			fee: 100,
			recipient: address(this),
			deadline: block.timestamp,
			amountOut: _amount,
			amountInMaximum: _amountInMaximum,
			sqrtPriceLimitX96: 0
		});
		// Executes the swap
		swapRouter.exactOutputSingle(params);
		// transfer any remainder funds back to the liquidity pool
		SafeTransferLib.safeTransfer(
			ERC20(collateralAsset),
			parentLiquidityPool,
			ERC20(collateralAsset).balanceOf(address(this))
		);
	}

	function _transferOut(uint256 _amount) internal {
		uint256 _amountOutMinimum = (_amount * 9950) / 10000;
		ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
			tokenIn: bridgedCollateralAsset,
			tokenOut: collateralAsset,
			fee: 100,
			recipient: parentLiquidityPool,
			deadline: block.timestamp,
			amountIn: _amount,
			amountOutMinimum: _amountOutMinimum,
			sqrtPriceLimitX96: 0
		});
		// Executes the swap
		swapRouter.exactInputSingle(params);
	}

	/// @dev keepers, managers or governors can access
	function _isKeeper() internal view {
		if (
			!keeper[msg.sender] &&
			msg.sender != authority.governor() &&
			msg.sender != authority.manager() &&
			msg.sender != parentLiquidityPool
		) {
			revert CustomErrors.NotKeeper();
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(uint80 _roundId)
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);

	function latestRoundData()
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface I_ERC20 {
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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9;

/// @title Accounting contract to calculate the dhv token value and handle deposit/withdraw mechanics

interface IAccounting {
	struct DepositReceipt {
		uint128 epoch;
		uint128 amount; // collateral decimals
		uint256 unredeemedShares; // e18
	}

	struct WithdrawalReceipt {
		uint128 epoch;
		uint128 shares; // e18
	}

	/**
	 * @notice logic for adding liquidity to the options liquidity pool
	 * @param  depositor the address making the deposit
	 * @param  _amount amount of the collateral asset to deposit
	 * @return depositAmount the amount to deposit from the round
	 * @return unredeemedShares number of shares held in the deposit receipt that havent been redeemed
	 */
	function deposit(address depositor, uint256 _amount)
		external
		returns (uint256 depositAmount, uint256 unredeemedShares);

	/**
	 * @notice logic for allowing a user to redeem their shares from a previous epoch
	 * @param  redeemer the address making the deposit
	 * @param  shares amount of the collateral asset to deposit
	 * @return toRedeem the amount to actually redeem
	 * @return depositReceipt the updated deposit receipt after the redeem has completed
	 */
	function redeem(address redeemer, uint256 shares)
		external
		returns (uint256 toRedeem, DepositReceipt memory depositReceipt);

	/**
	 * @notice logic for accounting a user to initiate a withdraw request from the pool
	 * @param  withdrawer the address carrying out the withdrawal
	 * @param  shares the amount of shares to withdraw for
	 * @return withdrawalReceipt the new withdrawal receipt to pass to the liquidityPool
	 */
	function initiateWithdraw(address withdrawer, uint256 shares)
		external
		returns (WithdrawalReceipt memory withdrawalReceipt);

	/**
	 * @notice logic for accounting a user to complete a withdrawal
	 * @param  withdrawer the address carrying out the withdrawal
	 * @return withdrawalAmount  the amount of collateral to withdraw
	 * @return withdrawalShares  the number of shares to withdraw
	 * @return withdrawalReceipt the new withdrawal receipt to pass to the liquidityPool
	 */
	function completeWithdraw(address withdrawer)
		external
		returns (
			uint256 withdrawalAmount,
			uint256 withdrawalShares,
			WithdrawalReceipt memory withdrawalReceipt
		);

	/**
	 * @notice execute the next epoch
	 * @param totalSupply  the total number of share tokens
	 * @param assets the amount of collateral assets
	 * @param liabilities the amount of liabilities of the pool
	 * @return newPricePerShareDeposit the price per share for deposits
	 * @return newPricePerShareWithdrawal the price per share for withdrawals
	 * @return sharesToMint the number of shares to mint this epoch
	 * @return totalWithdrawAmount the amount of collateral to set aside for partitioning
	 * @return amountNeeded the amount needed to reach the total withdraw amount if collateral balance of lp is insufficient
	 */
	function executeEpochCalculation(
		uint256 totalSupply,
		uint256 assets,
		int256 liabilities
	)
		external
		view
		returns (
			uint256 newPricePerShareDeposit,
			uint256 newPricePerShareWithdrawal,
			uint256 sharesToMint,
			uint256 totalWithdrawAmount,
			uint256 amountNeeded
		);

	/**
	 * @notice get the number of shares for a given amount
	 * @param _amount  the amount to convert to shares - assumed in collateral decimals
	 * @param assetPerShare the amount of assets received per share
	 * @return shares the number of shares based on the amount - assumed in e18
	 */
	function sharesForAmount(uint256 _amount, uint256 assetPerShare)
		external
		view
		returns (uint256 shares);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IAuthority {
	/* ========== EVENTS ========== */

	event GovernorPushed(address indexed from, address indexed to);
	event GuardianPushed(address indexed to);
	event ManagerPushed(address indexed from, address indexed to);

	event GovernorPulled(address indexed from, address indexed to);
	event GuardianRevoked(address indexed to);
	event ManagerPulled(address indexed from, address indexed to);

	/* ========== VIEW ========== */

	function governor() external view returns (address);

	function guardian(address _target) external view returns (bool);

	function manager() external view returns (address);

	function pullManager() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxVault {
	function isInitialized() external view returns (bool);

	function isSwapEnabled() external view returns (bool);

	function isLeverageEnabled() external view returns (bool);

	function setError(uint256 _errorCode, string calldata _error) external;

	function router() external view returns (address);

	function usdg() external view returns (address);

	function gov() external view returns (address);

	function whitelistedTokenCount() external view returns (uint256);

	function maxLeverage() external view returns (uint256);

	function minProfitTime() external view returns (uint256);

	function hasDynamicFees() external view returns (bool);

	function fundingInterval() external view returns (uint256);

	function totalTokenWeights() external view returns (uint256);

	function getTargetUsdgAmount(address _token) external view returns (uint256);

	function inManagerMode() external view returns (bool);

	function inPrivateLiquidationMode() external view returns (bool);

	function maxGasPrice() external view returns (uint256);

	function approvedRouters(address _account, address _router) external view returns (bool);

	function isLiquidator(address _account) external view returns (bool);

	function isManager(address _account) external view returns (bool);

	function minProfitBasisPoints(address _token) external view returns (uint256);

	function tokenBalances(address _token) external view returns (uint256);

	function lastFundingTimes(address _token) external view returns (uint256);

	function setMaxLeverage(uint256 _maxLeverage) external;

	function setInManagerMode(bool _inManagerMode) external;

	function setManager(address _manager, bool _isManager) external;

	function setIsSwapEnabled(bool _isSwapEnabled) external;

	function setIsLeverageEnabled(bool _isLeverageEnabled) external;

	function setMaxGasPrice(uint256 _maxGasPrice) external;

	function setUsdgAmount(address _token, uint256 _amount) external;

	function setBufferAmount(address _token, uint256 _amount) external;

	function setMaxGlobalShortSize(address _token, uint256 _amount) external;

	function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;

	function setLiquidator(address _liquidator, bool _isActive) external;

	function setFundingRate(
		uint256 _fundingInterval,
		uint256 _fundingRateFactor,
		uint256 _stableFundingRateFactor
	) external;

	function setFees(
		uint256 _taxBasisPoints,
		uint256 _stableTaxBasisPoints,
		uint256 _mintBurnFeeBasisPoints,
		uint256 _swapFeeBasisPoints,
		uint256 _stableSwapFeeBasisPoints,
		uint256 _marginFeeBasisPoints,
		uint256 _liquidationFeeUsd,
		uint256 _minProfitTime,
		bool _hasDynamicFees
	) external;

	function setTokenConfig(
		address _token,
		uint256 _tokenDecimals,
		uint256 _redemptionBps,
		uint256 _minProfitBps,
		uint256 _maxUsdgAmount,
		bool _isStable,
		bool _isShortable
	) external;

	function setPriceFeed(address _priceFeed) external;

	function withdrawFees(address _token, address _receiver) external returns (uint256);

	function directPoolDeposit(address _token) external;

	function buyUSDG(address _token, address _receiver) external returns (uint256);

	function sellUSDG(address _token, address _receiver) external returns (uint256);

	function swap(
		address _tokenIn,
		address _tokenOut,
		address _receiver
	) external returns (uint256);

	function increasePosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		uint256 _sizeDelta,
		bool _isLong
	) external;

	function decreasePosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		uint256 _collateralDelta,
		uint256 _sizeDelta,
		bool _isLong,
		address _receiver
	) external returns (uint256);

	function validateLiquidation(
		address _account,
		address _collateralToken,
		address _indexToken,
		bool _isLong,
		bool _raise
	) external view returns (uint256, uint256);

	function liquidatePosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		bool _isLong,
		address _feeReceiver
	) external;

	function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

	function priceFeed() external view returns (address);

	function fundingRateFactor() external view returns (uint256);

	function stableFundingRateFactor() external view returns (uint256);

	function cumulativeFundingRates(address _token) external view returns (uint256);

	function getNextFundingRate(address _token) external view returns (uint256);

	function getFeeBasisPoints(
		address _token,
		uint256 _usdgDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) external view returns (uint256);

	function liquidationFeeUsd() external view returns (uint256);

	function taxBasisPoints() external view returns (uint256);

	function stableTaxBasisPoints() external view returns (uint256);

	function mintBurnFeeBasisPoints() external view returns (uint256);

	function swapFeeBasisPoints() external view returns (uint256);

	function stableSwapFeeBasisPoints() external view returns (uint256);

	function marginFeeBasisPoints() external view returns (uint256);

	function allWhitelistedTokensLength() external view returns (uint256);

	function allWhitelistedTokens(uint256) external view returns (address);

	function whitelistedTokens(address _token) external view returns (bool);

	function stableTokens(address _token) external view returns (bool);

	function shortableTokens(address _token) external view returns (bool);

	function feeReserves(address _token) external view returns (uint256);

	function globalShortSizes(address _token) external view returns (uint256);

	function globalShortAveragePrices(address _token) external view returns (uint256);

	function maxGlobalShortSizes(address _token) external view returns (uint256);

	function tokenDecimals(address _token) external view returns (uint256);

	function tokenWeights(address _token) external view returns (uint256);

	function guaranteedUsd(address _token) external view returns (uint256);

	function poolAmounts(address _token) external view returns (uint256);

	function bufferAmounts(address _token) external view returns (uint256);

	function reservedAmounts(address _token) external view returns (uint256);

	function usdgAmounts(address _token) external view returns (uint256);

	function maxUsdgAmounts(address _token) external view returns (uint256);

	function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

	function getMaxPrice(address _token) external view returns (uint256);

	function getMinPrice(address _token) external view returns (uint256);

	function getDelta(
		address _indexToken,
		uint256 _size,
		uint256 _averagePrice,
		bool _isLong,
		uint256 _lastIncreasedTime
	) external view returns (bool, uint256);

	function getPosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		bool _isLong
	)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256,
			bool,
			uint256
		);

	function getPositionLeverage(
		address _account,
		address _collateralToken,
		address _indexToken,
		bool _isLong
	) external view returns (uint256);

	function getPositionKey(
		address _account,
		address _collateralToken,
		address _indexToken,
		bool _isLong
	) external pure returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9;

/// @title Reactors to hedge delta using means outside of the option pricing skew.

interface IHedgingReactor {
	/// @notice Execute a strategy to hedge delta exposure
	/// @param delta The exposure of the liquidity pool that the reactor needs to hedge against
	/// @return deltaChange The difference in delta exposure as a result of strategy execution
	function hedgeDelta(int256 delta) external returns (int256);

	/// @notice Returns the delta exposure of the reactor
	function getDelta() external view returns (int256 delta);

	/// @notice Returns the value of the reactor denominated in the liquidity pool asset
	/// @return value the value of the reactor in the liquidity pool asset
	function getPoolDenominatedValue() external view returns (uint256 value);

	/// @notice Withdraw a given asset from the hedging reactor to the calling liquidity pool.
	/// @param amount The amount to withdraw
	/// @return the amount actually withdrawn from the reactor denominated in the liquidity pool asset
	function withdraw(uint256 amount) external returns (uint256);

	/// @notice Handle events such as collateralisation rebalancing
	function update() external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9;

import { Types } from "../libraries/Types.sol";
import "../interfaces/IOptionRegistry.sol";
import "../interfaces/IAccounting.sol";
import "../interfaces/I_ERC20.sol";

interface ILiquidityPool is I_ERC20 {
	///////////////////////////
	/// immutable variables ///
	///////////////////////////
	function strikeAsset() external view returns (address);

	function underlyingAsset() external view returns (address);

	function collateralAsset() external view returns (address);

	/////////////////////////
	/// dynamic variables ///
	/////////////////////////

	function collateralAllocated() external view returns (uint256);

	function ephemeralLiabilities() external view returns (int256);

	function ephemeralDelta() external view returns (int256);

	function depositEpoch() external view returns (uint256);

	function withdrawalEpoch() external view returns (uint256);

	function depositEpochPricePerShare(uint256 epoch) external view returns (uint256 price);

	function withdrawalEpochPricePerShare(uint256 epoch) external view returns (uint256 price);

	function depositReceipts(address depositor)
		external
		view
		returns (IAccounting.DepositReceipt memory);

	function withdrawalReceipts(address withdrawer)
		external
		view
		returns (IAccounting.WithdrawalReceipt memory);

	function pendingDeposits() external view returns (uint256);

	function pendingWithdrawals() external view returns (uint256);

	function partitionedFunds() external view returns (uint256);

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	function bufferPercentage() external view returns (uint256);

	function collateralCap() external view returns (uint256);

	/////////////////
	/// functions ///
	/////////////////

	function adjustVariables(uint256 collateralAmount, uint256 optionsValue, int256 delta, bool isSale) external;
	
	function handlerIssue(Types.OptionSeries memory optionSeries) external returns (address);

	function resetEphemeralValues() external;

	function rebalancePortfolioDelta(int256 delta, uint256 index) external;
	
	function getAssets() external view returns (uint256);

	function redeem(uint256) external returns (uint256);

	function handlerWriteOption(
		Types.OptionSeries memory optionSeries,
		address seriesAddress,
		uint256 amount,
		IOptionRegistry optionRegistry,
		uint256 premium,
		int256 delta,
		address recipient
	) external returns (uint256);

	function handlerBuybackOption(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		IOptionRegistry optionRegistry,
		address seriesAddress,
		uint256 premium,
		int256 delta,
		address seller
	) external returns (uint256);

	function handlerIssueAndWriteOption(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		uint256 premium,
		int256 delta,
		address recipient
	) external returns (uint256, address);

	function getPortfolioDelta() external view returns (int256);

	function quotePriceWithUtilizationGreeks(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		bool toBuy
	) external view returns (uint256 quote, int256 delta);

	function checkBuffer() external view returns (int256 bufferRemaining);

	function getBalance(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import { Types } from "../libraries/Types.sol";

interface IOptionRegistry {
	//////////////////////////////////////////////////////
	/// access-controlled state changing functionality ///
	//////////////////////////////////////////////////////

	/**
	 * @notice Either retrieves the option token if it already exists, or deploy it
	 * @param  optionSeries option series to issue
	 * @return the address of the option
	 */
	function issue(Types.OptionSeries memory optionSeries) external returns (address);

	/**
	 * @notice Open an options contract using collateral from the liquidity pool
	 * @param  _series the address of the option token to be created
	 * @param  amount the amount of options to deploy
	 * @param  collateralAmount the collateral required for the option
	 * @dev only callable by the liquidityPool
	 * @return if the transaction succeeded
	 * @return the amount of collateral taken from the liquidityPool
	 */
	function open(
		address _series,
		uint256 amount,
		uint256 collateralAmount
	) external returns (bool, uint256);

	/**
	 * @notice Close an options contract (oToken) before it has expired
	 * @param  _series the address of the option token to be burnt
	 * @param  amount the amount of options to burn
	 * @dev only callable by the liquidityPool
	 * @return if the transaction succeeded
	 */
	function close(address _series, uint256 amount) external returns (bool, uint256);

	/////////////////////////////////////////////
	/// external state changing functionality ///
	/////////////////////////////////////////////

	/**
	 * @notice Settle an options vault
	 * @param  _series the address of the option token to be burnt
	 * @return success if the transaction succeeded
	 * @return collatReturned the amount of collateral returned from the vault
	 * @return collatLost the amount of collateral used to pay ITM options on vault settle
	 * @return amountShort number of oTokens that the vault was short
	 * @dev callable by anyone but returns funds to the liquidityPool
	 */
	function settle(address _series)
		external
		returns (
			bool success,
			uint256 collatReturned,
			uint256 collatLost,
			uint256 amountShort
		);

	///////////////////////
	/// complex getters ///
	///////////////////////

	/**
	 * @notice Send collateral funds for an option to be minted
	 * @dev series.strike should be scaled by 1e8.
	 * @param  series details of the option series
	 * @param  amount amount of options to mint
	 * @return amount transferred
	 */
	function getCollateral(Types.OptionSeries memory series, uint256 amount)
		external
		view
		returns (uint256);

	/**
	 * @notice Retrieves the option token if it exists
	 * @param  underlying is the address of the underlying asset of the option
	 * @param  strikeAsset is the address of the collateral asset of the option
	 * @param  expiration is the expiry timestamp of the option
	 * @param  isPut the type of option
	 * @param  strike is the strike price of the option - 1e18 format
	 * @param  collateral is the address of the asset to collateralize the option with
	 * @return the address of the option
	 */
	function getOtoken(
		address underlying,
		address strikeAsset,
		uint256 expiration,
		bool isPut,
		uint256 strike,
		address collateral
	) external view returns (address);

	///////////////////////////
	/// non-complex getters ///
	///////////////////////////

	function getSeriesInfo(address series) external view returns (Types.OptionSeries memory);
	function getSeries(Types.OptionSeries memory _series) external view returns (address);
	function vaultIds(address series) external view returns (uint256);
	function addressBook() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IPositionRouter {
	function createIncreasePosition(
		address[] memory _path,
		address _indexToken,
		uint256 _amountIn,
		uint256 _minOut,
		uint256 _sizeDelta,
		bool _isLong,
		uint256 _acceptablePrice,
		uint256 _executionFee,
		bytes32 _referralCode,
		address _callbackTarget
	) external payable returns (bytes32);

	function createDecreasePosition(
		address[] memory _path,
		address _indexToken,
		uint256 _collateralDelta,
		uint256 _sizeDelta,
		bool _isLong,
		address _receiver,
		uint256 _acceptablePrice,
		uint256 _minOut,
		uint256 _executionFee,
		bool _withdrawETH,
		address _callbackTarget
	) external payable returns (bytes32);

	function executeIncreasePosition(
		bytes32 _key,
		address payable _executionFeeReceiver
	) external returns (bool);

	function executeDecreasePosition(
		bytes32 _key,
		address payable _executionFeeReceiver
	) external returns (bool);

	function cancelIncreasePosition(
		bytes32 _key,
		address payable _executionFeeReceiver
	) external returns (bool);

	function cancelDecreasePosition(
		bytes32 _key,
		address payable _executionFeeReceiver
	) external returns (bool);

	function executeIncreasePositions(uint256, address payable) external;

	function executeDecreasePositions(uint256, address payable) external;

	function setPositionKeeper(address, bool) external;

	function admin() external view returns (address);

	function minExecutionFee() external view returns (uint256);

	function isLeverageEnabled() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IReader {
	function getPositions(
		address _vault,
		address _account,
		address[] memory _collateralTokens,
		address[] memory _indexTokens,
		bool[] memory _isLong
	) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IRouter {
	function addPlugin(address _plugin) external;

	function pluginTransfer(
		address _token,
		address _account,
		address _receiver,
		uint256 _amount
	) external;

	function pluginIncreasePosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		uint256 _sizeDelta,
		bool _isLong
	) external;

	function pluginDecreasePosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		uint256 _collateralDelta,
		uint256 _sizeDelta,
		bool _isLong,
		address _receiver
	) external returns (uint256);

	function swap(
		address[] memory _path,
		uint256 _amountIn,
		uint256 _minOut,
		address _receiver
	) external;

	function approvePlugin(address _plugin) external;

	function denyPlugin(address _plugin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IAuthority.sol";

error UNAUTHORIZED();

/**
 *  @title Contract used for access control functionality, based off of OlympusDao Access Control
 */
abstract contract AccessControl {
	/* ========== EVENTS ========== */

	event AuthorityUpdated(IAuthority authority);

	/* ========== STATE VARIABLES ========== */

	IAuthority public authority;

	/* ========== Constructor ========== */

	constructor(IAuthority _authority) {
		authority = _authority;
		emit AuthorityUpdated(_authority);
	}

	/* ========== GOV ONLY ========== */

	function setAuthority(IAuthority _newAuthority) external {
		_onlyGovernor();
		authority = _newAuthority;
		emit AuthorityUpdated(_newAuthority);
	}

	/* ========== INTERNAL CHECKS ========== */

	function _onlyGovernor() internal view {
		if (msg.sender != authority.governor()) revert UNAUTHORIZED();
	}

	function _onlyGuardian() internal view {
		if (!authority.guardian(msg.sender) && msg.sender != authority.governor()) revert UNAUTHORIZED();
	}

	function _onlyManager() internal view {
		if (msg.sender != authority.manager() && msg.sender != authority.governor())
			revert UNAUTHORIZED();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

import { NormalDist } from "./NormalDist.sol";

/**
 *  @title Library used to calculate an option price using Black Scholes
 */
library BlackScholes {
	using PRBMathSD59x18 for int256;
	using PRBMathSD59x18 for int8;
	using PRBMathUD60x18 for uint256;

	uint256 private constant ONE_YEAR_SECONDS = 31557600;
	uint256 private constant ONE = 1000000000000000000;
	uint256 private constant TWO = 2000000000000000000;

	struct Intermediates {
		uint256 d1Denominator;
		int256 d1;
		int256 eToNegRT;
	}

	function callOptionPrice(
		int256 d1,
		int256 d1Denominator,
		int256 price,
		int256 strike,
		int256 eToNegRT
	) public pure returns (uint256) {
		int256 d2 = d1 - d1Denominator;
		int256 cdfD1 = NormalDist.cdf(d1);
		int256 cdfD2 = NormalDist.cdf(d2);
		int256 priceCdf = price.mul(cdfD1);
		int256 strikeBy = strike.mul(eToNegRT).mul(cdfD2);
		assert(priceCdf >= strikeBy);
		return uint256(priceCdf - strikeBy);
	}

	function callOptionPriceGreeks(
		int256 d1,
		int256 d1Denominator,
		int256 price,
		int256 strike,
		int256 eToNegRT
	) public pure returns (uint256 quote, int256 delta) {
		int256 d2 = d1 - d1Denominator;
		int256 cdfD1 = NormalDist.cdf(d1);
		int256 cdfD2 = NormalDist.cdf(d2);
		int256 priceCdf = price.mul(cdfD1);
		int256 strikeBy = strike.mul(eToNegRT).mul(cdfD2);
		assert(priceCdf >= strikeBy);
		quote = uint256(priceCdf - strikeBy);
		delta = cdfD1;
	}

	function putOptionPriceGreeks(
		int256 d1,
		int256 d1Denominator,
		int256 price,
		int256 strike,
		int256 eToNegRT
	) public pure returns (uint256 quote, int256 delta) {
		int256 d2 = d1Denominator - d1;
		int256 cdfD1 = NormalDist.cdf(-d1);
		int256 cdfD2 = NormalDist.cdf(d2);
		int256 priceCdf = price.mul(cdfD1);
		int256 strikeBy = strike.mul(eToNegRT).mul(cdfD2);
		assert(strikeBy >= priceCdf);
		quote = uint256(strikeBy - priceCdf);
		delta = -cdfD1;
	}

	function putOptionPrice(
		int256 d1,
		int256 d1Denominator,
		int256 price,
		int256 strike,
		int256 eToNegRT
	) public pure returns (uint256) {
		int256 d2 = d1Denominator - d1;
		int256 cdfD1 = NormalDist.cdf(-d1);
		int256 cdfD2 = NormalDist.cdf(d2);
		int256 priceCdf = price.mul(cdfD1);
		int256 strikeBy = strike.mul(eToNegRT).mul(cdfD2);
		assert(strikeBy >= priceCdf);
		return uint256(strikeBy - priceCdf);
	}

	function getTimeStamp() private view returns (uint256) {
		return block.timestamp;
	}

	function getD1(
		uint256 price,
		uint256 strike,
		uint256 time,
		uint256 vol,
		uint256 rfr
	) private pure returns (int256 d1, uint256 d1Denominator) {
		uint256 d1Right = (vol.mul(vol).div(TWO) + rfr).mul(time);
		int256 d1Left = int256(price.div(strike)).ln();
		int256 d1Numerator = d1Left + int256(d1Right);
		d1Denominator = vol.mul(time.sqrt());
		d1 = d1Numerator.div(int256(d1Denominator));
	}

	function getIntermediates(
		uint256 price,
		uint256 strike,
		uint256 time,
		uint256 vol,
		uint256 rfr
	) private pure returns (Intermediates memory) {
		(int256 d1, uint256 d1Denominator) = getD1(price, strike, time, vol, rfr);
		return
			Intermediates({
				d1Denominator: d1Denominator,
				d1: d1,
				eToNegRT: (int256(rfr).mul(int256(time)).mul(-int256(ONE))).exp()
			});
	}

	function blackScholesCalc(
		uint256 price,
		uint256 strike,
		uint256 expiration,
		uint256 vol,
		uint256 rfr,
		bool isPut
	) public view returns (uint256) {
		uint256 time = (expiration - getTimeStamp()).div(ONE_YEAR_SECONDS);
		Intermediates memory i = getIntermediates(price, strike, time, vol, rfr);
		if (!isPut) {
			return
				callOptionPrice(
					int256(i.d1),
					int256(i.d1Denominator),
					int256(price),
					int256(strike),
					i.eToNegRT
				);
		} else {
			return
				putOptionPrice(
					int256(i.d1),
					int256(i.d1Denominator),
					int256(price),
					int256(strike),
					i.eToNegRT
				);
		}
	}

	function blackScholesCalcGreeks(
		uint256 price,
		uint256 strike,
		uint256 expiration,
		uint256 vol,
		uint256 rfr,
		bool isPut
	) public view returns (uint256 quote, int256 delta) {
		uint256 time = (expiration - getTimeStamp()).div(ONE_YEAR_SECONDS);
		Intermediates memory i = getIntermediates(price, strike, time, vol, rfr);
		if (!isPut) {
			return
				callOptionPriceGreeks(
					int256(i.d1),
					int256(i.d1Denominator),
					int256(price),
					int256(strike),
					i.eToNegRT
				);
		} else {
			return
				putOptionPriceGreeks(
					int256(i.d1),
					int256(i.d1Denominator),
					int256(price),
					int256(strike),
					i.eToNegRT
				);
		}
	}

	function getDelta(
		uint256 price,
		uint256 strike,
		uint256 expiration,
		uint256 vol,
		uint256 rfr,
		bool isPut
	) public view returns (int256) {
		uint256 time = (expiration - getTimeStamp()).div(ONE_YEAR_SECONDS);
		(int256 d1, ) = getD1(price, strike, time, vol, rfr);
		if (!isPut) {
			return NormalDist.cdf(d1);
		} else {
			return -NormalDist.cdf(-d1);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface CustomErrors {
	error NotKeeper();
	error IVNotFound();
	error NotHandler();
	error NotUpdater();
	error VaultExpired();
	error InvalidInput();
	error InvalidPrice();
	error InvalidBuyer();
	error InvalidOrder();
	error OrderExpired();
	error InvalidExpiry();
	error InvalidAmount();
	error TradingPaused();
	error InvalidAddress();
	error IssuanceFailed();
	error EpochNotClosed();
	error NoPositionsOpen();
	error InvalidDecimals();
	error InActivePosition();
	error NoActivePosition();
	error TradingNotPaused();
	error NotLiquidityPool();
	error UnauthorizedExit();
	error UnapprovedSeries();
	error SeriesNotBuyable();
	error ExchangeNotPaused();
	error DeltaNotDecreased();
	error NonExistentOtoken();
	error SeriesNotSellable();
	error InvalidGmxCallback();
	error GmxCallbackPending();
	error OrderExpiryTooLong();
	error InvalidShareAmount();
	error ExistingWithdrawal();
	error TotalSupplyReached();
	error StrikeAssetInvalid();
	error InsufficientBalance();
	error OptionStrikeInvalid();
	error OptionExpiryInvalid();
	error RangeOrderNotFilled();
	error NoExistingWithdrawal();
	error SpotMovedBeyondRange();
	error ReactorAlreadyExists();
	error UnauthorizedFulfill();
	error NonWhitelistedOtoken();
	error CollateralAssetInvalid();
	error UnderlyingAssetInvalid();
	error CollateralAmountInvalid();
	error WithdrawExceedsLiquidity();
	error InsufficientShareBalance();
	error MaxLiquidityBufferReached();
	error LiabilitiesGreaterThanAssets();
	error CustomOrderInsufficientPrice();
	error CustomOrderInvalidDeltaValue();
	error DeltaQuoteError(uint256 quote, int256 delta);
	error TimeDeltaExceedsThreshold(uint256 timeDelta);
	error PriceDeltaExceedsThreshold(uint256 priceDelta);
	error StrikeAmountExceedsLiquidity(uint256 strikeAmount, uint256 strikeLiquidity);
	error MinStrikeAmountExceedsLiquidity(uint256 strikeAmount, uint256 strikeAmountMin);
	error UnderlyingAmountExceedsLiquidity(uint256 underlyingAmount, uint256 underlyingLiquidity);
	error MinUnderlyingAmountExceedsLiquidity(uint256 underlyingAmount, uint256 underlyingAmountMin);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "prb-math/contracts/PRBMathSD59x18.sol";

/**
 *  @title Library used for approximating a normal distribution
 */
library NormalDist {
	using PRBMathSD59x18 for int256;

	int256 private constant ONE = 1000000000000000000;
	int256 private constant ONE_HALF = 500000000000000000;
	int256 private constant SQRT_TWO = 1414213562373095048;
	// z-scores
	// A1 0.254829592
	int256 private constant A1 = 254829592000000000;
	// A2 -0.284496736
	int256 private constant A2 = -284496736000000000;
	// A3 1.421413741
	int256 private constant A3 = 1421413741000000000;
	// A4 -1.453152027
	int256 private constant A4 = -1453152027000000000;
	// A5 1.061405429
	int256 private constant A5 = 1061405429000000000;
	// P 0.3275911
	int256 private constant P = 327591100000000000;

	function cdf(int256 x) public pure returns (int256) {
		int256 phiParam = x.div(SQRT_TWO);
		int256 onePlusPhi = ONE + (phi(phiParam));
		return ONE_HALF.mul(onePlusPhi);
	}

	function phi(int256 x) public pure returns (int256) {
		int256 sign = x >= 0 ? ONE : -ONE;
		int256 abs = x.abs();

		// A&S formula 7.1.26
		int256 t = ONE.div(ONE + (P.mul(abs)));
		int256 scoresByT = getScoresFromT(t);
		int256 eToXs = abs.mul(-ONE).mul(abs).exp();
		int256 y = ONE - (scoresByT.mul(eToXs));
		return sign.mul(y);
	}

	function getScoresFromT(int256 t) public pure returns (int256) {
		int256 byA5T = A5.mul(t);
		int256 byA4T = (byA5T + A4).mul(t);
		int256 byA3T = (byA4T + A3).mul(t);
		int256 byA2T = (byA3T + A2).mul(t);
		int256 byA1T = (byA2T + A1).mul(t);
		return byA1T;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Types.sol";
import "./CustomErrors.sol";
import "./BlackScholes.sol";
import "../tokens/ERC20.sol";

import "prb-math/contracts/PRBMathUD60x18.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";

/**
 *  @title Library used for various helper functionality for the Liquidity Pool
 */
library OptionsCompute {
	using PRBMathUD60x18 for uint256;
	using PRBMathSD59x18 for int256;

	uint8 private constant SCALE_DECIMALS = 18;
	uint256 private constant SCALE_UP = 10 ** 18;
	// oToken decimals
	uint8 private constant OPYN_DECIMALS = 8;
	// otoken conversion decimal
	uint8 private constant OPYN_CONVERSION_DECIMAL = 10;

	/// @dev assumes decimals are coming in as e18
	function convertToDecimals(uint256 value, uint256 decimals) internal pure returns (uint256) {
		if (decimals > SCALE_DECIMALS) {
			revert();
		}
		uint256 difference = SCALE_DECIMALS - decimals;
		return value / (10 ** difference);
	}

	/// @dev converts from specified decimals to e18
	function convertFromDecimals(
		uint256 value,
		uint256 decimals
	) internal pure returns (uint256 difference) {
		if (decimals > SCALE_DECIMALS) {
			revert();
		}
		difference = SCALE_DECIMALS - decimals;
		return value * (10 ** difference);
	}

	/// @dev converts from specified decimalsA to decimalsB
	function convertFromDecimals(
		uint256 value,
		uint8 decimalsA,
		uint8 decimalsB
	) internal pure returns (uint256) {
		uint8 difference;
		if (decimalsA > decimalsB) {
			difference = decimalsA - decimalsB;
			return value / (10 ** difference);
		}
		difference = decimalsB - decimalsA;
		return value * (10 ** difference);
	}

	// doesnt allow for interest bearing collateral
	function convertToCollateralDenominated(
		uint256 quote,
		uint256 underlyingPrice,
		Types.OptionSeries memory optionSeries
	) internal pure returns (uint256 convertedQuote) {
		if (optionSeries.strikeAsset != optionSeries.collateral) {
			// convert value from strike asset to collateral asset
			return (quote * SCALE_UP) / underlyingPrice;
		} else {
			return quote;
		}
	}

	/**
	 * @dev computes the percentage change between two integers
	 * @param n new value in e18
	 * @param o old value in e18
	 * @return pC uint256 the percentage change in e18
	 */
	function calculatePercentageChange(uint256 n, uint256 o) internal pure returns (uint256 pC) {
		// if new > old then its a percentage increase so do:
		// ((new - old) * 1e18) / old
		// if new < old then its a percentage decrease so do:
		// ((old - new) * 1e18) / old
		if (n > o) {
			pC = (n - o).div(o);
		} else {
			pC = (o - n).div(o);
		}
	}

	/**
	 * @notice get the latest oracle fed portfolio values and check when they were last updated and make sure this is within a reasonable window in
	 *		   terms of price and time
	 */
	function validatePortfolioValues(
		uint256 spotPrice,
		Types.PortfolioValues memory portfolioValues,
		uint256 maxTimeDeviationThreshold,
		uint256 maxPriceDeviationThreshold
	) public view {
		uint256 timeDelta = block.timestamp - portfolioValues.timestamp;
		// If too much time has passed we want to prevent a possible oracle attack
		if (timeDelta > maxTimeDeviationThreshold) {
			revert CustomErrors.TimeDeltaExceedsThreshold(timeDelta);
		}
		uint256 priceDelta = calculatePercentageChange(spotPrice, portfolioValues.spotPrice);
		// If price has deviated too much we want to prevent a possible oracle attack
		if (priceDelta > maxPriceDeviationThreshold) {
			revert CustomErrors.PriceDeltaExceedsThreshold(priceDelta);
		}
	}

	/**
	 * @notice Converts strike price to 1e8 format and floors least significant digits if needed
	 * @param  strikePrice strikePrice in 1e18 format
	 * @param  collateral address of collateral asset
	 * @return if the transaction succeeded
	 */
	function formatStrikePrice(uint256 strikePrice, address collateral) public view returns (uint256) {
		// convert strike to 1e8 format
		uint256 price = strikePrice / (10 ** OPYN_CONVERSION_DECIMAL);
		uint256 collateralDecimals = ERC20(collateral).decimals();
		if (collateralDecimals >= OPYN_DECIMALS) return price;
		uint256 difference = OPYN_DECIMALS - collateralDecimals;
		// round floor strike to prevent errors in Gamma protocol
		return (price / (10 ** difference)) * (10 ** difference);
	}

	/**
	 * @notice get the greeks of a quotePrice for a given optionSeries
	 * @param  optionSeries Types.OptionSeries struct for describing the option to price greeks - strike in e18
	 * @return quote           Quote price of the option - in e18
	 * @return delta           delta of the option being priced - in e18
	 */
	function quotePriceGreeks(
		Types.OptionSeries memory optionSeries,
		bool isBuying,
		uint256 bidAskIVSpread,
		uint256 riskFreeRate,
		uint256 iv,
		uint256 underlyingPrice,
		bool overrideIV
	) internal view returns (uint256 quote, int256 delta) {
		if (iv == 0) {
			revert CustomErrors.IVNotFound();
		}
		// reduce IV by a factor of bidAskIVSpread if we are buying the options
		if (isBuying && !overrideIV) {
			iv = (iv * (SCALE_UP - (bidAskIVSpread))) / SCALE_UP;
		}
		// revert CustomErrors.if the expiry is in the past
		if (optionSeries.expiration <= block.timestamp) {
			revert CustomErrors.OptionExpiryInvalid();
		}
		(quote, delta) = BlackScholes.blackScholesCalcGreeks(
			underlyingPrice,
			optionSeries.strike,
			optionSeries.expiration,
			iv,
			riskFreeRate,
			optionSeries.isPut
		);
	}

	function min(uint256 v1, uint256 v2) internal pure returns (uint256) {
		return v1 > v2 ? v2 : v1;
	}

	function max(int256 v1, int256 v2) internal pure returns (int256) {
		return v1 > v2 ? v1 : v2;
	}

	function toInt256(uint256 value) internal pure returns (int256) {
		// Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
		require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
		return int256(value);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) internal {
        ERC20 token = ERC20(tokenAddress);
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Types {
	struct OptionSeries {
		uint64 expiration;
		uint128 strike;
		bool isPut;
		address underlying;
		address strikeAsset;
		address collateral;
	}
	struct PortfolioValues {
		int256 delta;
		int256 gamma;
		int256 vega;
		int256 theta;
		int256 callPutsValue;
		uint256 timestamp;
		uint256 spotPrice;
	}
	struct Option {
		uint64 expiration;
		uint128 strike;
		bool isPut;
		bool isBuyable;
		bool isSellable;
	}
	struct Order {
		OptionSeries optionSeries;
		uint256 amount;
		uint256 price;
		uint256 orderExpiry;
		address buyer;
		address seriesAddress;
		uint128 lowerSpotMovementRange;
		uint128 upperSpotMovementRange;
		bool isBuyBack;
	}
	// strike and expiry date range for options
	struct OptionParams {
		uint128 minCallStrikePrice;
		uint128 maxCallStrikePrice;
		uint128 minPutStrikePrice;
		uint128 maxPutStrikePrice;
		uint128 minExpiry;
		uint128 maxExpiry;
	}

	struct UtilizationState {
		uint256 totalOptionPrice; //e18
		int256 totalDelta; // e18
		uint256 collateralToAllocate; //collateral decimals
		uint256 utilizationBefore; // e18
		uint256 utilizationAfter; //e18
		uint256 utilizationPrice; //e18
		bool isDecreased;
		uint256 deltaTiltAmount; //e18
		uint256 underlyingPrice; // strike asset decimals
		uint256 iv; // e18
	}

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./interfaces/AggregatorV3Interface.sol";

import "./libraries/AccessControl.sol";

/**
 *  @title Contract used for accessing exchange rates using chainlink price feeds
 *  @dev Interacts with chainlink price feeds and services all contracts in the system for price data.
 */
contract PriceFeed is AccessControl {
	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	mapping(address => mapping(address => address)) public priceFeeds;
	address public sequencerUptimeFeedAddress;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	uint8 private constant SCALE_DECIMALS = 18;
	// seconds since the last price feed update until we deem the data to be stale
	uint32 private constant STALE_PRICE_DELAY = 3600;
	// seconds after arbitrum sequencer comes back online that we start accepting price feed data
	uint32 private constant GRACE_PERIOD_TIME = 1800; // 30 minutes

	//////////////
	/// errors ///
	//////////////

	error SequencerDown();
	error GracePeriodNotOver();

	constructor(address _authority, address _sequencerUptimeFeedAddress)
		AccessControl(IAuthority(_authority))
	{
		sequencerUptimeFeedAddress = _sequencerUptimeFeedAddress;
	}

	///////////////
	/// setters ///
	///////////////

	function addPriceFeed(
		address underlying,
		address strike,
		address feed
	) public {
		_onlyGovernor();
		priceFeeds[underlying][strike] = feed;
	}

	function setSequencerUptimeFeedAddress(address _sequencerUptimeFeedAddress) external {
		_onlyGovernor();
		sequencerUptimeFeedAddress = _sequencerUptimeFeedAddress;
	}

	///////////////////////
	/// complex getters ///
	///////////////////////

	function getRate(address underlying, address strike) external view returns (uint256) {
		address feedAddress = priceFeeds[underlying][strike];
		require(feedAddress != address(0), "Price feed does not exist");
		AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
		// check arbitrum sequencer status
		_checkSequencerUp();
		(uint80 roundId, int256 rate, , uint256 timestamp, uint80 answeredInRound) = feed
			.latestRoundData();
		require(rate > 0, "ChainLinkPricer: price is lower than 0");
		require(timestamp != 0, "ROUND_NOT_COMPLETE");
		require(block.timestamp <= timestamp + STALE_PRICE_DELAY, "STALE_PRICE");
		require(answeredInRound >= roundId, "STALE_PRICE");
		return uint256(rate);
	}

	/// @dev get the rate from chainlink and convert it to e18 decimals
	function getNormalizedRate(address underlying, address strike) external view returns (uint256) {
		address feedAddress = priceFeeds[underlying][strike];
		require(feedAddress != address(0), "Price feed does not exist");
		AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
		uint8 feedDecimals = feed.decimals();
		// check arbitrum sequencer status
		_checkSequencerUp();
		(uint80 roundId, int256 rate, , uint256 timestamp, uint80 answeredInRound) = feed
			.latestRoundData();

		require(rate > 0, "ChainLinkPricer: price is lower than 0");
		require(timestamp != 0, "ROUND_NOT_COMPLETE");
		require(block.timestamp <= timestamp + STALE_PRICE_DELAY, "STALE_PRICE");
		require(answeredInRound >= roundId, "STALE_PRICE_ROUND");
		uint8 difference;
		if (SCALE_DECIMALS > feedDecimals) {
			difference = SCALE_DECIMALS - feedDecimals;
			return uint256(rate) * (10**difference);
		}
		difference = feedDecimals - SCALE_DECIMALS;
		return uint256(rate) / (10**difference);
	}

	/// @dev check arbitrum sequencer status and time since it last came back online
	function _checkSequencerUp() internal view {
		AggregatorV3Interface sequencerUptimeFeed = AggregatorV3Interface(sequencerUptimeFeedAddress);
		(, int256 answer, uint256 startedAt, , ) = sequencerUptimeFeed.latestRoundData();
		if (!(answer == 0)) {
			revert SequencerDown();
		}

		uint256 timeSinceUp = block.timestamp - startedAt;
		if (timeSinceUp <= GRACE_PERIOD_TIME) {
			revert GracePeriodNotOver();
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}