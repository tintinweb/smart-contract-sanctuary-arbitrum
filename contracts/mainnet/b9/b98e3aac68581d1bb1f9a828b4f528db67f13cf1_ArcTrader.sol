/**
 *Submitted for verification at Arbiscan.io on 2024-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
/*               _______            _                     __    __  
     /\         |__   __|          | |                   /_ |  / /  
    /  \   _ __ ___| |_ __ __ _  __| | ___ _ __  __   __  | | / /_  
   / /\ \ | '__/ __| | '__/ _` |/ _` |/ _ \ '__| \ \ / /  | || '_ \ 
  / ____ \| | | (__| | | | (_| | (_| |  __/ |     \ V /   | || (_) |
 /_/    \_\_|  \___|_|_|  \__,_|\__,_|\___|_|      \_/    |_(_)___/ 

  Changes from v 1.5:

  * Now for Archly V2, where the Arc token and factory addresses are the same on all
    chains so they are now hardcoded instead of being supplied to the constructor and
    the swap fee is now 0.3% (for volatile Arc pools).
  * Change the minimum amount to buy from a specific pool from 0.1 to 1 percent (to not
    waste gas for realistic buy/sell amounts)
*/

// Interfaces of external contracts we need to interact with (only the functions we use)
interface IERC20 {
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function symbol() external pure returns (string memory);
  function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);
}

interface IFactory {
  function getPair(address tokenA, address tokenB, bool stable) external view returns (address);
}

interface IPair {
  // The amounts of the two tokens (sorted by address) in the pair
  function getReserves() external view
    returns (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast);

  function swap(
    uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

// Conctract to buy and sell Arc from/to multiple pools in the same transaction
contract ArcTrader {
  // The Arc token address
  address constant private Arc = 0xe8876189A80B2079D8C0a7867e46c50361D972c1;

  // Address of the Archly pair factory
  address constant private PairFactory = 0x12508dd9108Abab2c5fD8fC6E4984E46a3CF7824;

  // The number of tokens that Arc may have pools with
  uint256 immutable public Count;

  // The tokens that Arc may have pools with (pools with other tokens will be ignored),
  // set once and for all in the constructor. Tokens with transfer tax are not supported.
  address[] public Tokens;

  // The Arc/Token (or Token/Arc) liquidity pools. This is set in the constructor but may
  // be updated to include newly added pools (with token from the Tokens array) by calling
  // the public function updatePools().
  address[] public Pools;

  // Used for packing and unpacking parameters to sell() and buy()
  uint256 constant private MAX128 = type(uint128).max;

  // "Magic" value for computing the checksum hash
  uint256 constant private CHECKSUM_MULTIPLIER = 0xbf58476d1ce4e5b9;

  // The following functions with names beginning with underscores are helper functions to make
  // the contract smaller and more readable.

  // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol
  function _log10(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
    unchecked {
      if (value >= 10 ** 64) {
        value /= 10 ** 64;
        result += 64;
      }
      if (value >= 10 ** 32) {
        value /= 10 ** 32;
        result += 32;
      }
      if (value >= 10 ** 16) {
        value /= 10 ** 16;
        result += 16;
      }
      if (value >= 10 ** 8) {
        value /= 10 ** 8;
        result += 8;
      }
      if (value >= 10 ** 4) {
        value /= 10 ** 4;
        result += 4;
      }
      if (value >= 10 ** 2) {
        value /= 10 ** 2;
        result += 2;
      }
      if (value >= 10 ** 1) {
        result += 1;
      }
    }
    return result;
  }

  // Converts a uint256 to a string representation
  // (Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol)
  bytes16 private constant _DIGITS = "0123456789";
  function _toString(uint256 value) internal pure returns (string memory) {
    unchecked {
      uint256 length = _log10(value) + 1;
      string memory buffer = new string(length);
      uint256 ptr;
      /// @solidity memory-safe-assembly
      assembly {
        ptr := add(buffer, add(32, length))
      }
      while (true) {
        ptr--;
        /// @solidity memory-safe-assembly
        assembly {
          mstore8(ptr, byte(mod(value, 10), _DIGITS))
        }
        value /= 10;
        if (value == 0) break;
      }
      return buffer;
    }
  }

  function _callerAllowance(address token, address spender) private view returns (uint256) {
    return IERC20(token).allowance(msg.sender, spender);
  }

  function _callerBalanceOf(address token) private view returns (uint256) {
    return IERC20(token).balanceOf(msg.sender);
  }

  function _transferFromCaller(address token, address to, uint256 amount) private {
    bool success = IERC20(token).transferFrom(msg.sender, to, amount);

    // Failure here is unexpected because we should have already checked the allowance and balance
    require(success, "ArcTrader: unexpected token transfer failure");
  }

  // Returns a (volatile) pair that token has with Arc, or the zero address if the pool does not exist.
  function _getPairWith(address token) private view returns (address) {
    return IFactory(PairFactory).getPair(Arc, token, false);
  }

  function _getReserves(address lpToken) private view returns (
    uint256 token0Reserve, uint256 token1Reserve) {
      (token0Reserve, token1Reserve, ) = IPair(lpToken).getReserves();
  }

  // Returns the Arc reserves for each potential pool (zero for non-existing pools) and the sum of them
  function _getArcReserves() private view returns (uint256[] memory arcReserves, uint256 total) {
    uint256 count = Count;
    arcReserves = new uint256[](count);
    unchecked {
      for (uint256 i = 0; i < count; ++i) {
        if (Pools[i] != address(0)) {
          (uint256 token0Reserve, uint256 token1Reserve) = _getReserves(Pools[i]);
          uint256 arcReserve = (Arc < Tokens[i]) ? token0Reserve : token1Reserve;
          arcReserves[i] = arcReserve;
          total += arcReserve;
        }
      }
    }
  }

  function _pairSwapToCaller(address pair, uint256 outAmount0, uint256 outAmount1) private {
    IPair(pair).swap(outAmount0, outAmount1, msg.sender, new bytes(0));
  }

  function _getToAmount(uint256 fromAmount, uint256 fromReserve, uint256 toReserve)
    private pure returns (uint256) {

    unchecked {
      // Note that these calculations (originally from UniSwapV2) only work for volatile pairs.
      uint256 fromAmountAfterFee = fromAmount * 9970;  // 0.3% fee
      uint256 numerator = fromAmountAfterFee * toReserve;
      uint256 denominator = (fromReserve * 10000) + fromAmountAfterFee;
      return numerator / denominator;
    }
  }

  function _getFromAmount(uint256 toAmount, uint256 fromReserve, uint256 toReserve)
    private pure returns (uint256) {

    unchecked {
      uint256 numerator = fromReserve * toAmount * 10000;
      uint256 denominator = (toReserve - toAmount) * 9970;  // 0.3% fee
      return (numerator / denominator) + 1;
    }
  }

  // Swaps a specific amount from one token to the other.
  // fromToken and toToken must be the tokens in the pair (not checked here).
  function _swapFromExact(address pair, address fromToken, address toToken, uint256 fromAmount)
    private returns (uint256 toAmount) {

    (uint256 fromReserve, uint256 toReserve) = _getReserves(pair);

    bool sorted = fromToken < toToken;
    if (!sorted) {
      (fromReserve, toReserve) = (toReserve, fromReserve);
    }

    _transferFromCaller(fromToken, pair, fromAmount);
    toAmount = _getToAmount(fromAmount, fromReserve, toReserve);

    if (sorted) {
      _pairSwapToCaller(pair, 0, toAmount);
    } else {
      _pairSwapToCaller(pair, toAmount, 0);
    }
  }

  // Swaps from one token to a specific amount of the other.
  // fromToken and toToken must be the tokens in the pair (not checked here).
  function _swapToExact(address pair, address fromToken, address toToken, uint256 toAmount)
    private returns (uint256 fromAmount) {

    (uint256 fromReserve, uint256 toReserve) = _getReserves(pair);

    bool sorted = fromToken < toToken;
    if (!sorted) {
      (fromReserve, toReserve) = (toReserve, fromReserve);
    }

    fromAmount = _getFromAmount(toAmount, fromReserve, toReserve);

    // Verify the caller's allowance and balance so we can provide descriptive error messages.
    require(_callerAllowance(fromToken, address(this)) >= fromAmount,
      string.concat(string.concat(
        "ArcTrader: insufficient ", IERC20(fromToken).symbol()), " allowance"));

    require(_callerBalanceOf(fromToken) >= fromAmount, string.concat(
      string.concat(
        "ArcTrader: insufficient ", IERC20(fromToken).symbol()),
        string.concat(
          " balance. Needs ", _toString(fromAmount))));

    _transferFromCaller(fromToken, pair, fromAmount);
    if (sorted) {
      _pairSwapToCaller(pair, 0, toAmount);
    } else {
      _pairSwapToCaller(pair, toAmount, 0);
    }
  }

  // The constructor sets all the tokens with which Arc will (potentially) have pools
  // (only volatile pools are considered).
  constructor(address[] memory tokens) {
    // Gas optimization is less important here but errors could cause headaches (and be
    // costly) so we include some extra checks with descriptive error messages.
    Count = tokens.length;
    require(Count >= 1, "ArcTrader: Arc must have a pool with at least one token");

    for (uint256 i = 0; i < Count; ++i) {
      require(tokens[i] != Arc, "ArcTrader: Arc cannot have a pair with itself");

      try IERC20(tokens[i]).balanceOf(address(this)) { }
      catch {
        revert("ArcTrader: one or more token addresses are not valid tokens");
      }

      for (uint256 j = 0; j < i; ++j) {
        require(tokens[i] != tokens[j], "ArcTrader: duplicate token");
      }

      Tokens.push(tokens[i]);
      Pools.push(address(0));
    }

    // Verify that the pair for the first token exists.
    address pairAddress = IFactory(PairFactory).getPair(Arc, tokens[0], false);
    require(pairAddress != address(0), "ArcTrader: a pool with the first token must exist");
    Pools[0] = pairAddress;

    // Find and save the pool addresses.
    updatePools();
  }

  // This function is called by the constructor and should also be called externally when
  // needsPoolUpdate() returns true.
  // (This is not done on every call to buy() and sell() because that would waste gas.)
  function updatePools() public {
    uint256 count = Count;
    unchecked {
      // The first pool has been set in the constructor so we start from index 1
      for (uint256 i = 1; i < count; ++i) {
        if (Pools[i] == address(0)) {
          Pools[i] = _getPairWith(Tokens[i]);
        }
      }
    }
  }

  // View function that will return true if we should call updatePools() because one or more new pools
  // (with tokens set in the constructor) have been created.
  function needsPoolUpdate() external view returns (bool) {
    uint256 count = Count;
    unchecked {
      for (uint256 i = 1; i < count; ++i) {
        if (Pools[i] == address(0)) {
          if (_getPairWith(Tokens[i]) != address(0)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // View function to get all the pool reserves.
  function getAllReserves() external view returns (
    uint256[] memory tokenReserves, uint256[] memory arcReserves) {

    uint256 count = Count;
    tokenReserves = new uint256[](count);
    arcReserves = new uint256[](count);

    unchecked {
      for (uint256 i = 0; i < count; ++i) {
        if (Pools[i] != address(0)) {
          (uint256 arcReserve, uint256 tokenReserve) = _getReserves(Pools[i]);
          if (Arc > Tokens[i]) {
            (arcReserve, tokenReserve) = (tokenReserve, arcReserve);
          }

          tokenReserves[i] = tokenReserve;
          arcReserves[i] = arcReserve;
        }
      }
    }
  }

  // Sells a specific amount of Arc for the other tokens in the right proportions.
  // The sell amount and desired checksum are packed as two 128-bit values in the parameter, with the
  // amount in integer Arc tokens (i.e. divided by 1e18).
  function sell(uint256 packedParams)
    external returns (uint256 checksum, uint256[] memory tokenAmounts) {

    uint256 arcSellAmount = (packedParams & MAX128) * 1e18;
    packedParams >>= 128;
    uint256 desiredChecksum = packedParams;

    return _sell(arcSellAmount, desiredChecksum);
  }

  // Sells exactly 100,000 Arc (without checksum check).
  function sell100k() external {
    _sell(100000 * 1e18, 0);
  }

  // Sells ALL the caller's Arc tokens (for convenience and gas savings on chains with expensive input).
  function sellAll() external {
    // Just call _sell() without our full balance and no checksum check.
    _sell(_callerBalanceOf(Arc), 0);
  }

  // Actual implementation of selling
  function _sell(uint256 arcSellAmount, uint256 desiredChecksum)
    private returns (uint256 checksum, uint256[] memory tokenAmounts) {

    require(arcSellAmount >= 1e18, "ArcTrader: cannot sell less than 1 Arc");
    require(_callerAllowance(Arc, address(this)) >= arcSellAmount,
      "ArcTrader: insufficient Arc allowance");

    // By checking that the caller balance is sufficient we not only can provide a descriptive
    // error message but also safely use unchecked math on arcSellAmount.
    require(_callerBalanceOf(Arc) >= arcSellAmount, "ArcTrader: insufficient Arc balance");

    // Get all the pool Arc reserves and the sum of them.
    (uint256[] memory arcReserves, uint256 totalArcReserve) = _getArcReserves();

    tokenAmounts = new uint256[](Count);

    // Compute how many Arc to sell into each pool and perform the swaps.
    uint256 arcSold = 0;
    checksum = 0;
    uint256 count = Count;

    unchecked {
      // Initially skip the first (always existing) pool; it will be used last.
      for (uint256 i = 1; i < count; ++i) {
        if (arcReserves[i] > 0) {
          uint256 poolSellAmount = arcSellAmount * arcReserves[i] / totalArcReserve;
          if (poolSellAmount >= arcSellAmount / 100) {
            // Use this pool if the swap amount is at least 1% of the total
            uint256 tokenAmount = _swapFromExact(Pools[i], Arc, Tokens[i], poolSellAmount);
            checksum = ((checksum ^ (checksum >> 30)) * CHECKSUM_MULTIPLIER) + tokenAmount;
            arcSold += poolSellAmount;
            tokenAmounts[i] = tokenAmount;
          }
        }
      }

      // The amount to sell into the first pool is simply what's left (this makes sure the total
      // number of Arc sold is exactly right).
      if (arcSellAmount > arcSold) {
        uint256 tokenAmount = _swapFromExact(Pools[0], Arc, Tokens[0], arcSellAmount - arcSold);
        checksum = ((checksum ^ (checksum >> 30)) * CHECKSUM_MULTIPLIER) + tokenAmount;
        tokenAmounts[0] = tokenAmount;
      }

      // Truncate checksum to 128 bits
      checksum = checksum & MAX128;

      // Revert if the checksum (if used) doesn't match. This means that some trade (in either
      // direction, or rarely a liquidity add or remove) happened between the checksum calculation and
      // this transaction.
      require(desiredChecksum == 0 || desiredChecksum == checksum, "ArcTrader: checksum mismatch");
    }
  }

  // Buys a specific amount of Arc (up to half of the existing reserves) using the right amount of all
  // the other tokens.
  // The buy amount and desired checksum are packed as two 128-bit values in the parameter, with the
  // amount in integer Arc tokens (i.e. divided by 1e18).
  // Note that spend approvals must have been given to all tokens (that will actually be used) and the
  // caller must have enough balance of them.
  function buy(uint256 packedParams)
    external returns (uint256 checksum, uint256[] memory tokenAmounts) {

    uint256 arcBuyAmount = (packedParams & MAX128) * 1e18; packedParams >>= 128;
    uint256 desiredChecksum = packedParams;

    return _buy(arcBuyAmount, desiredChecksum);
  }

  function _buy(uint256 arcBuyAmount, uint256 desiredChecksum) 
    private returns (uint256 checksum, uint256[] memory tokenAmounts) {

    require(arcBuyAmount >= 1e18, "ArcTrader: cannot buy less than 1 Arc");

    // Get all the pool reserves and the total amount of Arc reserves.
    (uint256[] memory arcReserves, uint256 totalArcReserve) = _getArcReserves();

    tokenAmounts = new uint256[](Count);

    unchecked {
      // By limiting the max amount to half of the total reserves (enough to quadruple the price)
      // we guard against mistakenly buying too much and can use unchecked math.
      require(arcBuyAmount <= totalArcReserve / 2,
        "ArcTrader: cannot buy more than half the pool reserves");

      // Compute how many Arc we want to get from each pool and perform the swaps.
      uint256 arcBought = 0;
      checksum = 0;
      uint256 count = Count;

      // Initially skip the first (always existing) pool; it will be used last.
      for (uint256 i = 1; i < count; ++i) {
        if (arcReserves[i] > 0) {
          uint256 poolBuyAmount = arcBuyAmount * arcReserves[i] / totalArcReserve;
          if (poolBuyAmount >= arcBuyAmount / 100) {
            // Use this pool if the swap amount is at least 1% of the total
            uint256 tokenAmount = _swapToExact(Pools[i], Tokens[i], Arc, poolBuyAmount);
            checksum = ((checksum ^ (checksum >> 30)) * CHECKSUM_MULTIPLIER) + tokenAmount;
            arcBought += poolBuyAmount;
            tokenAmounts[i] = tokenAmount;
          }
        }
      }

      // The amount to buy from the first pool is simply what's left (this makes sure the total
      // number of Arc bought is exactly right).
      if (arcBuyAmount > arcBought) {
        uint256 poolBuyAmount = arcBuyAmount - arcBought;
        uint256 tokenAmount = _swapToExact(Pools[0], Tokens[0], Arc, poolBuyAmount);
        checksum = ((checksum ^ (checksum >> 30)) * CHECKSUM_MULTIPLIER) + tokenAmount;
        tokenAmounts[0] = tokenAmount;
      }

      // Truncate checksum to 128 bits
      checksum = checksum & MAX128;

      // Revert if the checksum (if used) doesn't match. This means that some trade (in either
      // direction, or rarely a liquidity add or remove) happened between the checksum calculation and
      // this transaction.
      require(desiredChecksum == 0 || desiredChecksum == checksum, "ArcTrader: checksum mismatch");
    }
  }
}