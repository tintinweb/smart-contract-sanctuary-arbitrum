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

import { ILendgine } from "../core/interfaces/ILendgine.sol";
import { IPairMintCallback } from "../core/interfaces/callback/IPairMintCallback.sol";

import { FullMath } from "../libraries/FullMath.sol";
import { LendgineAddress } from "./libraries/LendgineAddress.sol";

/// @notice Manages liquidity provider positions
/// @author Kyle Scott ([email protected])
contract LiquidityManager is Multicall, Payment, SelfPermit, IPairMintCallback {
  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
  event AddLiquidity(
    address indexed from,
    address indexed lendgine,
    uint256 liquidity,
    uint256 size,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );

  event RemoveLiquidity(
    address indexed from,
    address indexed lendgine,
    uint256 liquidity,
    uint256 size,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );

  event Collect(address indexed from, address indexed lendgine, uint256 amount, address indexed to);

  /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

  error LivelinessError();

  error AmountError();

  error ValidationError();

  error PositionInvalidError();

  error CollectError();

  /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  address public immutable factory;

  struct Position {
    uint256 size;
    uint256 rewardPerPositionPaid;
    uint256 tokensOwed;
  }

  /// @notice Owner to lendgine to position
  mapping(address => mapping(address => Position)) public positions;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address _factory, address _weth) Payment(_weth) {
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
                                CALLBACK
    //////////////////////////////////////////////////////////////*/

  struct PairMintCallbackData {
    address token0;
    address token1;
    uint256 token0Exp;
    uint256 token1Exp;
    uint256 upperBound;
    uint256 amount0;
    uint256 amount1;
    address payer;
  }

  /// @notice callback that sends the underlying tokens for the specified amount of liquidity shares
  function pairMintCallback(uint256, bytes calldata data) external {
    PairMintCallbackData memory decoded = abi.decode(data, (PairMintCallbackData));

    address lendgine = LendgineAddress.computeAddress(
      factory, decoded.token0, decoded.token1, decoded.token0Exp, decoded.token1Exp, decoded.upperBound
    );
    if (lendgine != msg.sender) revert ValidationError();

    if (decoded.amount0 > 0) pay(decoded.token0, decoded.payer, msg.sender, decoded.amount0);
    if (decoded.amount1 > 0) pay(decoded.token1, decoded.payer, msg.sender, decoded.amount1);
  }

  /*//////////////////////////////////////////////////////////////
                        LIQUIDITY MANAGER LOGIC
    //////////////////////////////////////////////////////////////*/

  struct AddLiquidityParams {
    address token0;
    address token1;
    uint256 token0Exp;
    uint256 token1Exp;
    uint256 upperBound;
    uint256 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 sizeMin;
    address recipient;
    uint256 deadline;
  }

  /// @notice Add liquidity to a liquidity position
  function addLiquidity(AddLiquidityParams calldata params) external payable checkDeadline(params.deadline) {
    address lendgine = LendgineAddress.computeAddress(
      factory, params.token0, params.token1, params.token0Exp, params.token1Exp, params.upperBound
    );

    uint256 r0 = ILendgine(lendgine).reserve0();
    uint256 r1 = ILendgine(lendgine).reserve1();
    uint256 totalLiquidity = ILendgine(lendgine).totalLiquidity();

    uint256 amount0;
    uint256 amount1;

    if (totalLiquidity == 0) {
      amount0 = params.amount0Min;
      amount1 = params.amount1Min;
    } else {
      amount0 = FullMath.mulDivRoundingUp(params.liquidity, r0, totalLiquidity);
      amount1 = FullMath.mulDivRoundingUp(params.liquidity, r1, totalLiquidity);
    }

    if (amount0 < params.amount0Min || amount1 < params.amount1Min) revert AmountError();

    uint256 size = ILendgine(lendgine).deposit(
      address(this),
      params.liquidity,
      abi.encode(
        PairMintCallbackData({
          token0: params.token0,
          token1: params.token1,
          token0Exp: params.token0Exp,
          token1Exp: params.token1Exp,
          upperBound: params.upperBound,
          amount0: amount0,
          amount1: amount1,
          payer: msg.sender
        })
      )
    );
    if (size < params.sizeMin) revert AmountError();

    Position memory position = positions[params.recipient][lendgine]; // SLOAD

    (, uint256 rewardPerPositionPaid,) = ILendgine(lendgine).positions(address(this));
    position.tokensOwed += FullMath.mulDiv(position.size, rewardPerPositionPaid - position.rewardPerPositionPaid, 1e18);
    position.rewardPerPositionPaid = rewardPerPositionPaid;
    position.size += size;

    positions[params.recipient][lendgine] = position; // SSTORE

    emit AddLiquidity(msg.sender, lendgine, params.liquidity, size, amount0, amount1, params.recipient);
  }

  struct RemoveLiquidityParams {
    address token0;
    address token1;
    uint256 token0Exp;
    uint256 token1Exp;
    uint256 upperBound;
    uint256 size;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  /// @notice Removes from a liquidity position
  function removeLiquidity(RemoveLiquidityParams calldata params) external payable checkDeadline(params.deadline) {
    address lendgine = LendgineAddress.computeAddress(
      factory, params.token0, params.token1, params.token0Exp, params.token1Exp, params.upperBound
    );

    address recipient = params.recipient == address(0) ? address(this) : params.recipient;

    (uint256 amount0, uint256 amount1, uint256 liquidity) = ILendgine(lendgine).withdraw(recipient, params.size);
    if (amount0 < params.amount0Min || amount1 < params.amount1Min) revert AmountError();

    Position memory position = positions[msg.sender][lendgine]; // SLOAD

    (, uint256 rewardPerPositionPaid,) = ILendgine(lendgine).positions(address(this));
    position.tokensOwed += FullMath.mulDiv(position.size, rewardPerPositionPaid - position.rewardPerPositionPaid, 1e18);
    position.rewardPerPositionPaid = rewardPerPositionPaid;
    position.size -= params.size;

    positions[msg.sender][lendgine] = position; // SSTORE

    emit RemoveLiquidity(msg.sender, lendgine, liquidity, params.size, amount0, amount1, recipient);
  }

  struct CollectParams {
    address lendgine;
    address recipient;
    uint256 amountRequested;
  }

  /// @notice Collects interest owed to the callers liqudity position
  function collect(CollectParams calldata params) external payable returns (uint256 amount) {
    ILendgine(params.lendgine).accruePositionInterest();

    address recipient = params.recipient == address(0) ? address(this) : params.recipient;

    Position memory position = positions[msg.sender][params.lendgine]; // SLOAD

    (, uint256 rewardPerPositionPaid,) = ILendgine(params.lendgine).positions(address(this));
    position.tokensOwed += FullMath.mulDiv(position.size, rewardPerPositionPaid - position.rewardPerPositionPaid, 1e18);
    position.rewardPerPositionPaid = rewardPerPositionPaid;

    amount = params.amountRequested > position.tokensOwed ? position.tokensOwed : params.amountRequested;
    position.tokensOwed -= amount;

    positions[msg.sender][params.lendgine] = position; // SSTORE

    uint256 collectAmount = ILendgine(params.lendgine).collect(recipient, amount);
    if (collectAmount != amount) revert CollectError(); // extra check for safety

    emit Collect(msg.sender, params.lendgine, amount, recipient);
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