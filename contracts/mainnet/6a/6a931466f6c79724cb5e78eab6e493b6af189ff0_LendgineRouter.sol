// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

/// @notice Immutable state interface
/// @author Kyle Scott ([email protected])
interface IImmutableState {
  /// @notice The contract that deployed the lendgine
  function factory() external view returns (address);

  /// @notice The "numeraire" or "base" token in the pair
  function token0() external view returns (address);

  /// @notice The "risky" or "speculative" token in the pair
  function token1() external view returns (address);

  /// @notice Scale required to make token 0 18 decimals
  function token0Scale() external view returns (uint256);

  /// @notice Scale required to make token 1 18 decimals
  function token1Scale() external view returns (uint256);

  /// @notice Maximum exchange rate (token0/token1)
  function upperBound() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

import { IPair } from "./IPair.sol";

/// @notice Lending engine for borrowing and lending liquidity provider shares
/// @author Kyle Scott ([email protected])
interface ILendgine is IPair {
  /// @notice Returns information about a position given the controllers address
  function positions(address) external view returns (uint256, uint256, uint256);

  /// @notice The total amount of positions issued
  function totalPositionSize() external view returns (uint256);

  /// @notice The total amount of liquidity shares borrowed
  function totalLiquidityBorrowed() external view returns (uint256);

  /// @notice The amount of token1 rewarded to each unit of position
  function rewardPerPositionStored() external view returns (uint256);

  /// @notice The timestamp at which the interest was last accrued
  /// @dev don't downsize because it takes up the last slot
  function lastUpdate() external view returns (uint256);

  /// @notice Mint an option position by providing token1 as collateral and borrowing the max amount of liquidity
  /// @param to The address that receives the underlying tokens of the liquidity that is withdrawn
  /// @param collateral The amount of collateral in the position
  /// @param data The data to be passed through to the callback
  /// @return shares The amount of shares that were minted
  /// @dev A callback is invoked on the caller
  function mint(address to, uint256 collateral, bytes calldata data) external returns (uint256 shares);

  /// @notice Burn an option position by minting the required liquidity and unlocking the collateral
  /// @param to The address to send the unlocked collateral to
  /// @param data The data to be passed through to the callback
  /// @dev Send the amount to burn before calling this function
  /// @dev A callback is invoked on the caller
  function burn(address to, bytes calldata data) external returns (uint256 collateral);

  /// @notice Provide liquidity to the underlying AMM
  /// @param to The address that will control the position
  /// @param liquidity The amount of liquidity shares that will be minted
  /// @param data The data to be passed through to the callback
  /// @return size The size of the position that was minted
  /// @dev A callback is invoked on the caller
  function deposit(address to, uint256 liquidity, bytes calldata data) external returns (uint256 size);

  /// @notice Withdraw liquidity from the underlying AMM
  /// @param to The address to receive the underlying tokens of the AMM
  /// @param size The size of the position to be withdrawn
  /// @return amount0 The amount of token0 that was withdrawn
  /// @return amount1 The amount of token1 that was withdrawn
  /// @return liquidity The amount of liquidity shares that were withdrawn
  function withdraw(address to, uint256 size) external returns (uint256 amount0, uint256 amount1, uint256 liquidity);

  /// @notice Accrues the global interest by decreasing the total amount of liquidity owed by borrowers and rewarding
  /// lenders with the borrowers collateral
  function accrueInterest() external;

  /// @notice Accrues interest for the caller's liquidity position
  /// @dev Reverts if the sender doesn't have a position
  function accruePositionInterest() external;

  /// @notice Collects the interest that has been gathered to a liquidity position
  /// @param to The address that recieves the collected interest
  /// @param collateralRequested The amount of interest to collect
  /// @return collateral The amount of interest that was actually collected
  function collect(address to, uint256 collateralRequested) external returns (uint256 collateral);

  /// @notice Accounting logic for converting liquidity to share amount
  function convertLiquidityToShare(uint256 liquidity) external view returns (uint256);

  /// @notice Accounting logic for converting share amount to liqudity
  function convertShareToLiquidity(uint256 shares) external view returns (uint256);

  /// @notice Accounting logic for converting collateral amount to liquidity
  function convertCollateralToLiquidity(uint256 collateral) external view returns (uint256);

  /// @notice Accounting logic for converting liquidity to collateral amount
  function convertLiquidityToCollateral(uint256 liquidity) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

import { IImmutableState } from "./IImmutableState.sol";

/// @notice AMM implementing the capped power invariant
/// @author Kyle Scott ([email protected])
interface IPair is IImmutableState {
  /// @notice The amount of token0 in the pair
  function reserve0() external view returns (uint120);

  /// @notice The amount of token1 in the pair
  function reserve1() external view returns (uint120);

  /// @notice The total amount of liquidity shares in the pair
  function totalLiquidity() external view returns (uint256);

  /// @notice The implementation of the capped power invariant
  /// @return valid True if the invariant is satisfied
  function invariant(uint256 amount0, uint256 amount1, uint256 liquidity) external view returns (bool);

  /// @notice Exchange between token0 and token1, either accepts or rejects the proposed trade
  /// @param data The data to be passed through to the callback
  /// @dev A callback is invoked on the caller
  function swap(address to, uint256 amount0Out, uint256 amount1Out, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

interface IMintCallback {
  /// @notice Called to `msg.sender` after executing a mint via Lendgine
  /// @dev In the implementation you must pay the speculative tokens owed for the mint.
  /// The caller of this method must be checked to be a Lendgine deployed by the canonical Factory.
  /// @param data Any data passed through by the caller via the Mint call
  function mintCallback(
    uint256 collateral,
    uint256 amount0,
    uint256 amount1,
    uint256 liquidity,
    bytes calldata data
  )
    external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IPairMintCallback {
  /// @notice Called to `msg.sender` after executing a mint via Pair
  /// @dev In the implementation you must pay the pool tokens owed for the mint.
  /// The caller of this method must be checked to be a Pair deployed by the canonical Factory.
  /// @param data Any data passed through by the caller via the Mint call
  function pairMintCallback(uint256 liquidity, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

/// @notice Library for safely and cheaply reading balances
/// @author Kyle Scott ([email protected])
/// @author Modified from UniswapV3Pool
/// (https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L140-L145)
library Balance {
  error BalanceReturnError();

  /// @notice Determine the callers balance of the specified token
  function balance(address token) internal view returns (uint256) {
    (bool success, bytes memory data) =
      token.staticcall(abi.encodeWithSelector(bytes4(keccak256(bytes("balanceOf(address)"))), address(this)));
    if (!success || data.length < 32) revert BalanceReturnError();
    return abi.decode(data, (uint256));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable max-line-length

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of
/// precision
/// @author Muffin (https://github.com/muffinfi/muffin/blob/master/contracts/libraries/math/FullMath.sol)
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256
/// bits
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or
  /// denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
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

      // [*] The next line is edited to be compatible with solidity 0.8
      // ref: https://ethereum.stackexchange.com/a/96646
      // original: uint256 twos = -denominator & denominator;
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

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or
  /// denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
    result = mulDiv(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      result++;
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/// @notice Library for safely and cheaply casting solidity types
/// @author Kyle Scott ([email protected])
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/SafeCast.sol)
library SafeCast {
  function toUint120(uint256 y) internal pure returns (uint120 z) {
    require((z = uint120(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2 ** 255);
    z = int256(y);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// solhint-disable max-line-length

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Muffin (https://github.com/muffinfi/muffin/blob/master/contracts/libraries/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free
/// memory pointer.
library SafeTransferLib {
  error FailedTransferETH();
  error FailedTransfer();
  error FailedTransferFrom();
  error FailedApprove();

  /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

  function safeTransferETH(address to, uint256 amount) internal {
    bool callStatus;

    assembly {
      // Transfer the ETH and store if it succeeded or not.
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }

    if (!callStatus) revert FailedTransferETH();
  }

  /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

  function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
    bool callStatus;

    assembly {
      // Get a pointer to some free memory.
      let freeMemoryPointer := mload(0x40)

      // Write the abi-encoded calldata to memory piece by piece:
      mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with
      // the function selector.
      mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append
      // the "from" argument.
      mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append
      // the "to" argument.
      mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full
      // 32 byte value.

      // Call the token and store if it succeeded or not.
      // We use 100 because the calldata length is 4 + 32 * 3.
      callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
    }

    if (!didLastOptionalReturnCallSucceed(callStatus)) revert FailedTransferFrom();
  }

  function safeTransfer(address token, address to, uint256 amount) internal {
    bool callStatus;

    assembly {
      // Get a pointer to some free memory.
      let freeMemoryPointer := mload(0x40)

      // Write the abi-encoded calldata to memory piece by piece:
      mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with
      // the function selector.
      mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append
      // the "to" argument.
      mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full
      // 32 byte value.

      // Call the token and store if it succeeded or not.
      // We use 68 because the calldata length is 4 + 32 * 2.
      callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
    }

    if (!didLastOptionalReturnCallSucceed(callStatus)) revert FailedTransfer();
  }

  /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

  function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
    assembly {
      // If the call reverted:
      if iszero(callStatus) {
        // Copy the revert message into memory.
        returndatacopy(0, 0, returndatasize())

        // Revert with the same message.
        revert(0, returndatasize())
      }

      switch returndatasize()
      case 32 {
        // Copy the return data into memory.
        returndatacopy(0, 0, returndatasize())

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import { Multicall } from "./Multicall.sol";
import { Payment } from "./Payment.sol";
import { SelfPermit } from "./SelfPermit.sol";
import { SwapHelper } from "./SwapHelper.sol";

import { ILendgine } from "../core/interfaces/ILendgine.sol";
import { IMintCallback } from "../core/interfaces/callback/IMintCallback.sol";
import { IPairMintCallback } from "../core/interfaces/callback/IPairMintCallback.sol";

import { FullMath } from "../libraries/FullMath.sol";
import { LendgineAddress } from "./libraries/LendgineAddress.sol";
import { SafeCast } from "../libraries/SafeCast.sol";
import { SafeTransferLib } from "../libraries/SafeTransferLib.sol";

/// @notice Contract for automatically entering and exiting option positions
/// @author Kyle Scott ([email protected])
contract LendgineRouter is Multicall, Payment, SelfPermit, SwapHelper, IMintCallback, IPairMintCallback {
  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Mint(address indexed from, address indexed lendgine, uint256 collateral, uint256 shares, address indexed to);

  event Burn(address indexed from, address indexed lendgine, uint256 collateral, uint256 shares, address indexed to);

  /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

  error LivelinessError();

  error ValidationError();

  error AmountError();

  /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  address public immutable factory;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(
    address _factory,
    address _uniswapV2Factory,
    address _uniswapV3Factory,
    address _weth
  )
    SwapHelper(_uniswapV2Factory, _uniswapV3Factory)
    Payment(_weth)
  {
    factory = _factory;
  }

  /*//////////////////////////////////////////////////////////////
                           LIVELINESS MODIFIER
    //////////////////////////////////////////////////////////////*/

  modifier checkDeadline(uint256 deadline) {
    if (deadline < block.timestamp) revert LivelinessError();
    _;
  }

  /*//////////////////////////////////////////////////////////////
                               MINT LOGIC
    //////////////////////////////////////////////////////////////*/

  struct MintCallbackData {
    address token0;
    address token1;
    uint256 token0Exp;
    uint256 token1Exp;
    uint256 upperBound;
    uint256 collateralMax;
    SwapType swapType;
    bytes swapExtraData;
    address payer;
  }

  /// @notice Transfer the necessary amount of token1 to mint an option position
  function mintCallback(
    uint256 collateralTotal,
    uint256 amount0,
    uint256 amount1,
    uint256,
    bytes calldata data
  )
    external
    override
  {
    MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));

    address lendgine = LendgineAddress.computeAddress(
      factory, decoded.token0, decoded.token1, decoded.token0Exp, decoded.token1Exp, decoded.upperBound
    );
    if (lendgine != msg.sender) revert ValidationError();

    // swap all token0 to token1
    uint256 collateralSwap = swap(
      decoded.swapType,
      SwapParams({
        tokenIn: decoded.token0,
        tokenOut: decoded.token1,
        amount: SafeCast.toInt256(amount0),
        recipient: msg.sender
      }),
      decoded.swapExtraData
    );

    // send token1 back
    SafeTransferLib.safeTransfer(decoded.token1, msg.sender, amount1);

    // pull the rest of tokens from the user
    uint256 collateralIn = collateralTotal - amount1 - collateralSwap;
    if (collateralIn > decoded.collateralMax) revert AmountError();

    pay(decoded.token1, decoded.payer, msg.sender, collateralIn);
  }

  struct MintParams {
    address token0;
    address token1;
    uint256 token0Exp;
    uint256 token1Exp;
    uint256 upperBound;
    uint256 amountIn;
    uint256 amountBorrow;
    uint256 sharesMin;
    SwapType swapType;
    bytes swapExtraData;
    address recipient;
    uint256 deadline;
  }

  /// @notice Use token1 to completely mint an option position
  function mint(MintParams calldata params) external payable checkDeadline(params.deadline) returns (uint256 shares) {
    address lendgine = LendgineAddress.computeAddress(
      factory, params.token0, params.token1, params.token0Exp, params.token1Exp, params.upperBound
    );

    shares = ILendgine(lendgine).mint(
      address(this),
      params.amountIn + params.amountBorrow,
      abi.encode(
        MintCallbackData({
          token0: params.token0,
          token1: params.token1,
          token0Exp: params.token0Exp,
          token1Exp: params.token1Exp,
          upperBound: params.upperBound,
          collateralMax: params.amountIn,
          swapType: params.swapType,
          swapExtraData: params.swapExtraData,
          payer: msg.sender
        })
      )
    );
    if (shares < params.sharesMin) revert AmountError();

    SafeTransferLib.safeTransfer(lendgine, params.recipient, shares);

    emit Mint(msg.sender, lendgine, params.amountIn, shares, params.recipient);
  }

  /*//////////////////////////////////////////////////////////////
                               BURN LOGIC
    //////////////////////////////////////////////////////////////*/

  struct PairMintCallbackData {
    address token0;
    address token1;
    uint256 token0Exp;
    uint256 token1Exp;
    uint256 upperBound;
    uint256 collateralMin;
    uint256 amount0Min;
    uint256 amount1Min;
    SwapType swapType;
    bytes swapExtraData;
    address recipient;
  }

  /// @notice Provide the tokens for the liquidity that is owed
  function pairMintCallback(uint256 liquidity, bytes calldata data) external override {
    PairMintCallbackData memory decoded = abi.decode(data, (PairMintCallbackData));

    address lendgine = LendgineAddress.computeAddress(
      factory, decoded.token0, decoded.token1, decoded.token0Exp, decoded.token1Exp, decoded.upperBound
    );
    if (lendgine != msg.sender) revert ValidationError();

    uint256 r0 = ILendgine(msg.sender).reserve0();
    uint256 r1 = ILendgine(msg.sender).reserve1();
    uint256 totalLiquidity = ILendgine(msg.sender).totalLiquidity();

    uint256 amount0;
    uint256 amount1;

    if (totalLiquidity == 0) {
      amount0 = decoded.amount0Min;
      amount1 = decoded.amount1Min;
    } else {
      amount0 = FullMath.mulDivRoundingUp(liquidity, r0, totalLiquidity);
      amount1 = FullMath.mulDivRoundingUp(liquidity, r1, totalLiquidity);
    }

    if (amount0 < decoded.amount0Min || amount1 < decoded.amount1Min) revert AmountError();

    // swap for required token0
    uint256 collateralSwapped = swap(
      decoded.swapType,
      SwapParams({
        tokenIn: decoded.token1,
        tokenOut: decoded.token0,
        amount: -SafeCast.toInt256(amount0),
        recipient: msg.sender
      }),
      decoded.swapExtraData
    );

    // pay token1
    SafeTransferLib.safeTransfer(decoded.token1, msg.sender, amount1);

    // determine remaining and send to recipient
    uint256 collateralTotal = ILendgine(msg.sender).convertLiquidityToCollateral(liquidity);
    uint256 collateralOut = collateralTotal - amount1 - collateralSwapped;
    if (collateralOut < decoded.collateralMin) revert AmountError();

    if (decoded.recipient != address(this)) {
      SafeTransferLib.safeTransfer(decoded.token1, decoded.recipient, collateralOut);
    }
  }

  struct BurnParams {
    address token0;
    address token1;
    uint256 token0Exp;
    uint256 token1Exp;
    uint256 upperBound;
    uint256 shares;
    uint256 collateralMin;
    uint256 amount0Min;
    uint256 amount1Min;
    SwapType swapType;
    bytes swapExtraData;
    address recipient;
    uint256 deadline;
  }

  /// @notice Take an option position and withdraw it fully into token1
  function burn(BurnParams calldata params) external payable checkDeadline(params.deadline) returns (uint256 amount) {
    address lendgine = LendgineAddress.computeAddress(
      factory, params.token0, params.token1, params.token0Exp, params.token1Exp, params.upperBound
    );

    address recipient = params.recipient == address(0) ? address(this) : params.recipient;

    SafeTransferLib.safeTransferFrom(lendgine, msg.sender, lendgine, params.shares);

    amount = ILendgine(lendgine).burn(
      address(this),
      abi.encode(
        PairMintCallbackData({
          token0: params.token0,
          token1: params.token1,
          token0Exp: params.token0Exp,
          token1Exp: params.token1Exp,
          upperBound: params.upperBound,
          collateralMin: params.collateralMin,
          amount0Min: params.amount0Min,
          amount1Min: params.amount1Min,
          swapType: params.swapType,
          swapExtraData: params.swapExtraData,
          recipient: recipient
        })
      )
    );

    emit Burn(msg.sender, lendgine, amount, params.shares, recipient);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
/// @author Muffin (https://github.com/muffinfi/muffin/blob/master/contracts/periphery/base/Multicall.sol)
/// @dev Widened solidity version from 0.8.10
abstract contract Multicall is IMulticall {
  /// @inheritdoc IMulticall
  function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
    results = new bytes[](data.length);
    unchecked {
      for (uint256 i = 0; i < data.length; i++) {
        (bool success, bytes memory result) = address(this).delegatecall(data[i]);

        if (!success) {
          if (result.length == 0) revert();
          assembly {
            revert(add(32, result), mload(result))
          }
        }

        results[i] = result;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

import { IWETH9 } from "./interfaces/external/IWETH9.sol";

import { Balance } from "./../libraries/Balance.sol";
import { SafeTransferLib } from "./../libraries/SafeTransferLib.sol";

/// @title   Payment contract
/// @author  https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/PeripheryPayments.sol
/// @notice  Functions to ease deposits and withdrawals of ETH
abstract contract Payment {
  address public immutable weth;

  error InsufficientOutputError();

  constructor(address _weth) {
    weth = _weth;
  }

  receive() external payable {
    require(msg.sender == weth, "Not WETH9");
  }

  function unwrapWETH(uint256 amountMinimum, address recipient) public payable {
    uint256 balanceWETH = Balance.balance(weth);
    if (balanceWETH < amountMinimum) revert InsufficientOutputError();

    if (balanceWETH > 0) {
      IWETH9(weth).withdraw(balanceWETH);
      SafeTransferLib.safeTransferETH(recipient, balanceWETH);
    }
  }

  function sweepToken(address token, uint256 amountMinimum, address recipient) public payable {
    uint256 balanceToken = Balance.balance(token);
    if (balanceToken < amountMinimum) revert InsufficientOutputError();

    if (balanceToken > 0) {
      SafeTransferLib.safeTransfer(token, recipient, balanceToken);
    }
  }

  function refundETH() external payable {
    if (address(this).balance > 0) SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
  }

  /// @param token The token to pay
  /// @param payer The entity that must pay
  /// @param recipient The entity that will receive payment
  /// @param value The amount to pay
  function pay(address token, address payer, address recipient, uint256 value) internal {
    if (token == weth && address(this).balance >= value) {
      // pay with WETH
      IWETH9(weth).deposit{ value: value }(); // wrap only what is needed to pay
      SafeTransferLib.safeTransfer(weth, recipient, value);
    } else if (payer == address(this)) {
      // pay with tokens already in the contract (for the exact input multihop case)
      SafeTransferLib.safeTransfer(token, recipient, value);
    } else {
      // pull payment
      SafeTransferLib.safeTransferFrom(token, payer, recipient, value);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/external/IERC20Permit.sol";
import "./interfaces/external/IERC20PermitAllowed.sol";
import "./interfaces/ISelfPermit.sol";

/// @author Muffin (https://github.com/muffinfi/muffin/blob/master/contracts/periphery/base/SelfPermit.sol)
/// @dev Widened solidity version from 0.8.10
abstract contract SelfPermit is ISelfPermit {
  /// @notice Permits this contract to spend a given token from `msg.sender`
  /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
  /// @param token The address of the token spent
  /// @param value The amount that can be spent of token
  /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
  /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function selfPermit(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable {
    IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
  }

  /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
  /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
  /// @param token The address of the token spent
  /// @param nonce The current nonce of the owner
  /// @param expiry The timestamp at which the permit is no longer valid
  /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function selfPermitAllowed(
    address token,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
    payable
  {
    IERC20PermitAllowed(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import { IUniswapV2Pair } from "./UniswapV2/interfaces/IUniswapV2Pair.sol";
import { IUniswapV3Pool } from "./UniswapV3/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3SwapCallback } from "./UniswapV3/interfaces/callback/IUniswapV3SwapCallback.sol";

import { PoolAddress } from "./UniswapV3/libraries/PoolAddress.sol";
import { SafeTransferLib } from "../libraries/SafeTransferLib.sol";
import { TickMath } from "./UniswapV3/libraries/TickMath.sol";
import { UniswapV2Library } from "./UniswapV2/libraries/UniswapV2Library.sol";

/// @notice Allows for swapping on Uniswap V2 or V3
/// @author Kyle Scott ([email protected])
abstract contract SwapHelper is IUniswapV3SwapCallback {
  /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  /// @dev should match the init code hash in the UniswapV2Library
  address public immutable uniswapV2Factory;

  address public immutable uniswapV3Factory;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address _uniswapV2Factory, address _uniswapV3Factory) {
    uniswapV2Factory = _uniswapV2Factory;
    uniswapV3Factory = _uniswapV3Factory;
  }

  /*//////////////////////////////////////////////////////////////
                        UNISWAPV3 SWAP CALLBACK
    //////////////////////////////////////////////////////////////*/

  function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
    address tokenIn = abi.decode(data, (address));
    // no validation because this contract should hold no tokens between transactions

    SafeTransferLib.safeTransfer(tokenIn, msg.sender, amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta));
  }

  /*//////////////////////////////////////////////////////////////
                               SWAP LOGIC
    //////////////////////////////////////////////////////////////*/

  enum SwapType {
    UniswapV2,
    UniswapV3
  }

  struct SwapParams {
    address tokenIn;
    address tokenOut;
    int256 amount; // negative corresponds to exact out
    address recipient;
  }

  struct UniV3Data {
    uint24 fee;
  }

  /// @notice Handles swaps on Uniswap V2 or V3
  /// @param swapType A selector for UniswapV2 or V3
  /// @param data Extra data that is not used by all types of swaps
  /// @return amount The amount in or amount out depending on whether the call was exact in or exact out
  function swap(SwapType swapType, SwapParams memory params, bytes memory data) internal returns (uint256 amount) {
    if (swapType == SwapType.UniswapV2) {
      address pair = UniswapV2Library.pairFor(uniswapV2Factory, params.tokenIn, params.tokenOut);

      (uint256 reserveIn, uint256 reserveOut) =
        UniswapV2Library.getReserves(uniswapV2Factory, params.tokenIn, params.tokenOut);

      amount = params.amount > 0
        ? UniswapV2Library.getAmountOut(uint256(params.amount), reserveIn, reserveOut)
        : UniswapV2Library.getAmountIn(uint256(-params.amount), reserveIn, reserveOut);

      (uint256 amountIn, uint256 amountOut) =
        params.amount > 0 ? (uint256(params.amount), amount) : (amount, uint256(-params.amount));

      (address token0,) = UniswapV2Library.sortTokens(params.tokenIn, params.tokenOut);
      (uint256 amount0Out, uint256 amount1Out) =
        params.tokenIn == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

      SafeTransferLib.safeTransfer(params.tokenIn, pair, amountIn);
      IUniswapV2Pair(pair).swap(amount0Out, amount1Out, params.recipient, bytes(""));
    } else {
      UniV3Data memory uniV3Data = abi.decode(data, (UniV3Data));

      // Borrowed logic from https://github.com/Uniswap/v3-periphery/blob/main/contracts/SwapRouter.sol
      // exactInputInternal and exactOutputInternal

      bool zeroForOne = params.tokenIn < params.tokenOut;

      IUniswapV3Pool pool = IUniswapV3Pool(
        PoolAddress.computeAddress(
          uniswapV3Factory, PoolAddress.getPoolKey(params.tokenIn, params.tokenOut, uniV3Data.fee)
        )
      );

      (int256 amount0, int256 amount1) = pool.swap(
        params.recipient,
        zeroForOne,
        params.amount,
        zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
        abi.encode(params.tokenIn)
      );

      if (params.amount > 0) {
        amount = uint256(-(zeroForOne ? amount1 : amount0));
      } else {
        int256 amountOutReceived;
        (amount, amountOutReceived) = zeroForOne ? (uint256(amount0), amount1) : (uint256(amount1), amount0);
        require(amountOutReceived == params.amount);
      }
    }
  }
}

pragma solidity >=0.5.0;

/// @author Uniswap (https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol)
interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

pragma solidity >=0.8.0;

import { IUniswapV2Pair } from "../interfaces/IUniswapV2Pair.sol";

/// @notice Library for helpful UniswapV2 functions
/// @author Uniswap (https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol)
/// @dev Updated for newer solidity by removing safe math
library UniswapV2Library {
  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint160( // extra cast for newer solidity
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
            )
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  )
    internal
    view
    returns (uint256 reserveA, uint256 reserveB)
  {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  )
    internal
    pure
    returns (uint256 amountOut)
  {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    uint256 amountInWithFee = amountIn * 997;
    uint256 numerator = amountInWithFee * reserveOut;
    uint256 denominator = (reserveIn * 1000) + amountInWithFee;
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  )
    internal
    pure
    returns (uint256 amountIn)
  {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    uint256 numerator = reserveIn * amountOut * 1000;
    uint256 denominator = (reserveOut - amountOut) * 997;
    amountIn = (numerator / denominator) + 1;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./pool/IUniswapV3PoolImmutables.sol";
import "./pool/IUniswapV3PoolState.sol";
import "./pool/IUniswapV3PoolDerivedState.sol";
import "./pool/IUniswapV3PoolActions.sol";
import "./pool/IUniswapV3PoolOwnerActions.sol";
import "./pool/IUniswapV3PoolEvents.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
  IUniswapV3PoolImmutables,
  IUniswapV3PoolState,
  IUniswapV3PoolDerivedState,
  IUniswapV3PoolActions,
  IUniswapV3PoolOwnerActions,
  IUniswapV3PoolEvents
{ }

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
  function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
  /// @notice Sets the initial price for the pool
  /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
  /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
  function initialize(uint160 sqrtPriceX96) external;

  /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
  /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
  /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
  /// on tickLower, tickUpper, the amount of liquidity, and the current price.
  /// @param recipient The address for which the liquidity will be created
  /// @param tickLower The lower tick of the position in which to add liquidity
  /// @param tickUpper The upper tick of the position in which to add liquidity
  /// @param amount The amount of liquidity to mint
  /// @param data Any data that should be passed through to the callback
  /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in
  /// the callback
  /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in
  /// the callback
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount,
    bytes calldata data
  )
    external
    returns (uint256 amount0, uint256 amount1);

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
  )
    external
    returns (uint128 amount0, uint128 amount1);

  /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
  /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
  /// @dev Fees must be collected separately via a call to #collect
  /// @param tickLower The lower tick of the position for which to burn liquidity
  /// @param tickUpper The upper tick of the position for which to burn liquidity
  /// @param amount How much liquidity to burn
  /// @return amount0 The amount of token0 sent to the recipient
  /// @return amount1 The amount of token1 sent to the recipient
  function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);

  /// @notice Swap token0 for token1, or token1 for token0
  /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
  /// @param recipient The address to receive the output of the swap
  /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive),
  /// or exact output (negative)
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
  )
    external
    returns (int256 amount0, int256 amount1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
  /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
  /// with 0 amount{0,1} and sending the donation amount(s) from the callback
  /// @param recipient The address which will receive the token0 and token1 amounts
  /// @param amount0 The amount of token0 to send
  /// @param amount1 The amount of token1 to send
  /// @param data Any data to be passed through to the callback
  function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

  /// @notice Increase the maximum number of price and liquidity observations that this pool will store
  /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
  /// the input observationCardinalityNext.
  /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
  function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
  /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block
  /// timestamp
  /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one
  /// representing
  /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted
  /// average tick,
  /// you must call it with secondsAgos = [3600, 0].
  /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
  /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
  /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
  /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
  /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each
  /// `secondsAgos` from the current block
  /// timestamp
  function observe(uint32[] calldata secondsAgos)
    external
    view
    returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

  /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
  /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
  /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
  /// snapshot is taken and the second snapshot is taken.
  /// @param tickLower The lower tick of the range
  /// @param tickUpper The upper tick of the range
  /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
  /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
  /// @return secondsInside The snapshot of seconds per liquidity for the range
  function snapshotCumulativesInside(
    int24 tickLower,
    int24 tickUpper
  )
    external
    view
    returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
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
    address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1
  );

  /// @notice Emitted by the pool for increases to the number of observations that can be stored
  /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
  /// just before a mint/swap/burn.
  /// @param observationCardinalityNextOld The previous value of the next observation cardinality
  /// @param observationCardinalityNextNew The updated value of the next observation cardinality
  event IncreaseObservationCardinalityNext(uint16 observationCardinalityNextOld, uint16 observationCardinalityNextNew);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
  /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
  /// @return The contract address
  function factory() external view returns (address);

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
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
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
  )
    external
    returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
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

  /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the
  /// pool
  /// @dev This value can overflow the uint256
  function feeGrowthGlobal0X128() external view returns (uint256);

  /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the
  /// pool
  /// @dev This value can overflow the uint256
  function feeGrowthGlobal1X128() external view returns (uint256);

  /// @notice The amounts of token0 and token1 that are owed to the protocol
  /// @dev Protocol fees will never exceed uint128 max in either token
  function protocolFees() external view returns (uint128 token0, uint128 token1);

  /// @notice The currently in range liquidity available to the pool
  /// @dev This value has no relationship to the total liquidity across all ticks
  function liquidity() external view returns (uint128);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
  /// tick upper,
  /// liquidityNet how much liquidity changes when the pool price crosses the tick,
  /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
  /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
  /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
  /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current
  /// tick,
  /// secondsOutside the seconds spent on the other side of the tick from the current tick,
  /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to
  /// false.
  /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
  /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
  /// a specific position.
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
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
  function positions(bytes32 key)
    external
    view
    returns (
      uint128 _liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  /// @notice Returns data about a specific observation index
  /// @param index The element of the observations array to fetch
  /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of
  /// time
  /// ago, rather than at a specific index in the array.
  /// @return blockTimestamp The timestamp of the observation,
  /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation
  /// timestamp,
  /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the
  /// observation timestamp,
  /// Returns initialized whether the observation has been initialized and the values are safe to use
  function observations(uint256 index)
    external
    view
    returns (uint32 blockTimestamp, int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128, bool initialized);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
  bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

  /// @notice The identifying key of the pool
  struct PoolKey {
    address token0;
    address token1;
    uint24 fee;
  }

  /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
  /// @param tokenA The first token of a pool, unsorted
  /// @param tokenB The second token of a pool, unsorted
  /// @param fee The fee level of the pool
  /// @return Poolkey The pool details with ordered token0 and token1 assignments
  function getPoolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (PoolKey memory) {
    if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
    return PoolKey({ token0: tokenA, token1: tokenB, fee: fee });
  }

  /// @notice Deterministically computes the pool address given the factory and PoolKey
  /// @param factory The Uniswap V3 factory contract address
  /// @param key The PoolKey
  /// @return pool The contract address of the V3 pool
  function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
    require(key.token0 < key.token1);
    pool = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff", factory, keccak256(abi.encode(key.token0, key.token1, key.fee)), POOL_INIT_CODE_HASH
            )
          )
        )
      )
    );
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  int24 internal constant MIN_TICK = -887_272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 internal constant MAX_TICK = -MIN_TICK;

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4_295_128_739;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_342;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
/// @author Muffin (https://github.com/muffinfi/muffin/blob/master/contracts/interfaces/common/IMulticall.sol)
interface IMulticall {
  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ISelfPermit {
  /// @notice Permits this contract to spend a given token from `msg.sender`
  /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
  /// @param token The address of the token spent
  /// @param value The amount that can be spent of token
  /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
  /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function selfPermit(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable;

  /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
  /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
  /// @param token The address of the token spent
  /// @param nonce The current nonce of the owner
  /// @param expiry The timestamp at which the permit is no longer valid
  /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function selfPermitAllowed(
    address token,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
    payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
  )
    external;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title   Interface for permit
/// @notice  Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
  /// @notice         Approve the spender to spend some tokens via the holder signature
  /// @dev            This is the permit interface used by DAI and CHAI
  /// @param holder   Address of the token holder, the token owner
  /// @param spender  Address of the token spender
  /// @param nonce    Holder's nonce, increases at each call to permit
  /// @param expiry   Timestamp at which the permit is no longer valid
  /// @param allowed  Boolean that sets approval amount, true for type(uint256).max and false for 0
  /// @param v        Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r        Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s        Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Interface for WETH
interface IWETH9 {
  /// @notice Wraps ETH into WETH
  function deposit() external payable;

  /// @notice Unwraps WETH into ETH
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

/// @notice Library for computing the address of a lendgine using only its inputs
library LendgineAddress {
  uint256 internal constant INIT_CODE_HASH =
    54_077_118_415_036_375_799_727_632_405_414_219_288_686_146_435_384_080_671_378_369_222_491_001_741_386;

  function computeAddress(
    address factory,
    address token0,
    address token1,
    uint256 token0Exp,
    uint256 token1Exp,
    uint256 upperBound
  )
    internal
    pure
    returns (address lendgine)
  {
    lendgine = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encode(token0, token1, token0Exp, token1Exp, upperBound)),
              bytes32(INIT_CODE_HASH)
            )
          )
        )
      )
    );
  }
}