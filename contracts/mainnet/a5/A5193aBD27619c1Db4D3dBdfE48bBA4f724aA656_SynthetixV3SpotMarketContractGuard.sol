// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {IGuard} from "../../../interfaces/guards/IGuard.sol";
import {IAtomicOrderModule} from "../../../interfaces/synthetixV3/IAtomicOrderModule.sol";
import {ISpotMarketFactoryModule} from "../../../interfaces/synthetixV3/ISpotMarketFactoryModule.sol";
import {ISynthetixV3ContractGuard} from "../../../interfaces/synthetixV3/ISynthetixV3ContractGuard.sol";
import {IWrapperModule} from "../../../interfaces/synthetixV3/IWrapperModule.sol";
import {IHasGuardInfo} from "../../../interfaces/IHasGuardInfo.sol";
import {IPoolLogic} from "../../../interfaces/IPoolLogic.sol";
import {IPoolManagerLogic} from "../../../interfaces/IPoolManagerLogic.sol";
import {ITransactionTypes} from "../../../interfaces/ITransactionTypes.sol";
import {SynthetixV3Structs} from "../../../utils/synthetixV3/libraries/SynthetixV3Structs.sol";
import {PrecisionHelper} from "../../../utils/PrecisionHelper.sol";
import {TxDataUtils} from "../../../utils/TxDataUtils.sol";

contract SynthetixV3SpotMarketContractGuard is IGuard, TxDataUtils, ITransactionTypes {
  using SafeMath for uint256;
  using PrecisionHelper for address;

  address public immutable snxV3Core;

  ISpotMarketFactoryModule public immutable snxSpotMarket;

  mapping(address => SynthetixV3Structs.AllowedMarket) public allowedMarkets;

  /// @dev Address is required to get its contract guard which stores the whitelist of dHEDGE vaults
  /// @param _snxV3Core Synthetix V3 core address
  /// @param _allowedMarkets Synthetix markets ids allowed for trading
  constructor(address _snxV3Core, address _snxSpotMarket, SynthetixV3Structs.AllowedMarket[] memory _allowedMarkets) {
    require(_snxV3Core != address(0), "invalid snxV3Core");
    require(_snxSpotMarket != address(0), "invalid snxSpotMarket");

    snxV3Core = _snxV3Core;
    snxSpotMarket = ISpotMarketFactoryModule(_snxSpotMarket);

    for (uint256 i; i < _allowedMarkets.length; ++i) {
      require(
        ISpotMarketFactoryModule(_snxSpotMarket).getSynth(_allowedMarkets[i].marketId) ==
          _allowedMarkets[i].collateralSynth,
        "invalid market config"
      );
      require(_allowedMarkets[i].collateralAsset != address(0), "invalid collateral address");
      allowedMarkets[_allowedMarkets[i].collateralSynth] = _allowedMarkets[i];
    }
  }

  /// @notice Transaction guard for Synthetix V3 Spot Market
  /// @notice Supports only 1:1 synths buy/sell and collateral wrap/unwrap
  /// @dev Can be called only by PoolLogic during execTransaction
  /// @dev Only available for SynthetixV3 whitelisted vaults
  /// @dev Includes synths wrapping/unwrapping and buying/selling
  /// @dev Matching values like amount and minAmountReceived in the transactions will guarantee the 1:1 swap
  /// @param _poolManagerLogic Pool manager logic address
  /// @param _data Transaction data
  /// @return txType Transaction type
  /// @return isPublic If the transaction is public or private
  function txGuard(
    address _poolManagerLogic,
    address,
    bytes memory _data
  ) external override returns (uint16 txType, bool) {
    address poolLogic = IPoolManagerLogic(_poolManagerLogic).poolLogic();

    require(msg.sender == poolLogic, "not pool logic");

    ISynthetixV3ContractGuard coreContractGuard = ISynthetixV3ContractGuard(
      IHasGuardInfo(IPoolLogic(poolLogic).factory()).getContractGuard(snxV3Core)
    );

    require(coreContractGuard.isVaultWhitelisted(poolLogic), "dhedge vault not whitelisted");

    bytes4 method = getMethod(_data);
    bytes memory params = getParams(_data);

    if (method == IWrapperModule.wrap.selector) {
      (uint128 marketId, uint256 wrapAmount, uint256 minAmountReceived) = abi.decode(
        params,
        (uint128, uint256, uint256)
      );

      SynthetixV3Structs.AllowedMarket storage allowedMarket = _validateMarketId(marketId);
      wrapAmount = wrapAmount.mul(allowedMarket.collateralAsset.getPrecisionForConversion());

      require(wrapAmount == minAmountReceived, "amounts don't match");

      txType = uint16(TransactionType.SynthetixV3Wrap);

      emit SynthetixV3Event(poolLogic, txType);
    } else if (method == IWrapperModule.unwrap.selector) {
      (uint128 marketId, uint256 unwrapAmount, uint256 minAmountReceived) = abi.decode(
        params,
        (uint128, uint256, uint256)
      );

      SynthetixV3Structs.AllowedMarket storage allowedMarket = _validateMarketId(marketId);
      minAmountReceived = minAmountReceived.mul(allowedMarket.collateralAsset.getPrecisionForConversion());

      require(unwrapAmount == minAmountReceived, "amounts don't match");

      txType = uint16(TransactionType.SynthetixV3Unwrap);

      emit SynthetixV3Event(poolLogic, txType);
    } else if (method == IAtomicOrderModule.buy.selector || method == IAtomicOrderModule.buyExactIn.selector) {
      (uint128 marketId, uint256 usdAmount, uint256 minSynthAmount) = abi.decode(params, (uint128, uint256, uint256));

      _validateMarketId(marketId);

      require(usdAmount == minSynthAmount, "amounts don't match");

      txType = uint16(TransactionType.SynthetixV3BuySynth);

      emit SynthetixV3Event(poolLogic, txType);
    } else if (method == IAtomicOrderModule.sell.selector || method == IAtomicOrderModule.sellExactIn.selector) {
      (uint128 marketId, uint256 synthAmount, uint256 minUsdAmount) = abi.decode(params, (uint128, uint256, uint256));

      _validateMarketId(marketId);

      require(synthAmount == minUsdAmount, "amounts don't match");

      txType = uint16(TransactionType.SynthetixV3SellSynth);

      emit SynthetixV3Event(poolLogic, txType);
    }

    return (txType, false);
  }

  function _validateMarketId(
    uint128 _marketId
  ) internal view returns (SynthetixV3Structs.AllowedMarket storage allowedMarket) {
    require(_marketId > 0, "invalid marketId");
    address synthAddress = snxSpotMarket.getSynth(_marketId);
    allowedMarket = allowedMarkets[synthAddress];
    require(allowedMarket.marketId == _marketId, "market not allowed");
  }
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGuard {
  event ExchangeFrom(address fundAddress, address sourceAsset, uint256 sourceAmount, address dstAsset, uint256 time);
  event ExchangeTo(address fundAddress, address sourceAsset, address dstAsset, uint256 dstAmount, uint256 time);

  function txGuard(
    address poolManagerLogic,
    address to,
    bytes calldata data
  ) external returns (uint16 txType, bool isPublic); // TODO: eventually update `txType` to be of enum type as per ITransactionTypes
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <=0.8.10;

// With aditional optional views

interface IERC20Extended {
  // ERC20 Optional Views
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  // Views
  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function scaledBalanceOf(address user) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  // Mutative functions
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  // Events
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasGuardInfo {
  // Get guard
  function getContractGuard(address extContract) external view returns (address);

  // Get asset guard
  function getAssetGuard(address extContract) external view returns (address);

  // Get mapped addresses from Governance
  function getAddress(bytes32 name) external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPoolLogic {
  function factory() external view returns (address);

  function poolManagerLogic() external view returns (address);

  function setPoolManagerLogic(address _poolManagerLogic) external returns (bool);

  function availableManagerFee() external view returns (uint256 fee);

  function tokenPrice() external view returns (uint256 price);

  function tokenPriceWithoutManagerFee() external view returns (uint256 price);

  function mintManagerFee() external;

  function deposit(address _asset, uint256 _amount) external returns (uint256 liquidityMinted);

  function depositFor(address _recipient, address _asset, uint256 _amount) external returns (uint256 liquidityMinted);

  function depositForWithCustomCooldown(
    address _recipient,
    address _asset,
    uint256 _amount,
    uint256 _cooldown
  ) external returns (uint256 liquidityMinted);

  function withdraw(uint256 _fundTokenAmount) external;

  function transfer(address to, uint256 value) external returns (bool);

  function balanceOf(address owner) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function symbol() external view returns (string memory);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function getExitRemainingCooldown(address sender) external view returns (uint256 remaining);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPoolManagerLogic {
  function poolLogic() external view returns (address);

  function isDepositAsset(address asset) external view returns (bool);

  function validateAsset(address asset) external view returns (bool);

  function assetValue(address asset) external view returns (uint256);

  function assetValue(address asset, uint256 amount) external view returns (uint256);

  function assetBalance(address asset) external view returns (uint256 balance);

  function factory() external view returns (address);

  function setPoolLogic(address fundAddress) external returns (bool);

  function totalFundValue() external view returns (uint256);

  function totalFundValueMutable() external returns (uint256);

  function isMemberAllowed(address member) external view returns (bool);

  function getFee() external view returns (uint256, uint256, uint256, uint256);

  function minDepositUSD() external view returns (uint256);
}

//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Transaction type events used in pool execTransaction() contract guards
/// @dev Gradually migrate to these events as we update / add new contract guards
interface ITransactionTypes {
  // Transaction Types in execTransaction()
  // 1. Approve: Approving a token for spending by different address/contract
  // 2. Exchange: Exchange/trade of tokens eg. Uniswap, Synthetix
  // 3. AddLiquidity: Add liquidity
  event AddLiquidity(address poolLogic, address pair, bytes params, uint256 time);
  // 4. RemoveLiquidity: Remove liquidity
  event RemoveLiquidity(address poolLogic, address pair, bytes params, uint256 time);
  // 5. Stake: Stake tokens into a third party contract (eg. Sushi yield farming)
  event Stake(address poolLogic, address stakingToken, address to, uint256 amount, uint256 time);
  // 6. Unstake: Unstake tokens from a third party contract (eg. Sushi yield farming)
  event Unstake(address poolLogic, address stakingToken, address to, uint256 amount, uint256 time);
  // 7. Claim: Claim rewards tokens from a third party contract (eg. SUSHI & MATIC rewards)
  event Claim(address poolLogic, address stakingContract, uint256 time);
  // 8. UnstakeAndClaim: Unstake tokens and claim rewards from a third party contract
  // 9. Deposit: Aave deposit tokens -> get Aave Interest Bearing Token
  // 10. Withdraw: Withdraw tokens from Aave Interest Bearing Token
  // 11. SetUserUseReserveAsCollateral: Aave set reserve asset to be used as collateral
  // 12. Borrow: Aave borrow tokens
  // 13. Repay: Aave repay tokens
  // 14. SwapBorrowRateMode: Aave change borrow rate mode (stable/variable)
  // 15. RebalanceStableBorrowRate: Aave rebalance stable borrow rate
  // 16. JoinPool: Balancer join pool
  // 17. ExitPool: Balancer exit pool
  // 18. Deposit: EasySwapper Deposit
  // 19. Withdraw: EasySwapper Withdraw
  // 20. Mint: Uniswap V3 Mint position
  // 21. IncreaseLiquidity: Uniswap V3 increase liquidity position
  // 22. DecreaseLiquidity: Uniswap V3 decrease liquidity position
  // 23. Burn: Uniswap V3 Burn position
  // 24. Collect: Uniswap V3 collect fees
  // 25. Multicall: Uniswap V3 Multicall
  // 26. Lyra: open position
  // 27. Lyra: close position
  // 28. Lyra: force close position
  // 29. Futures: Market
  // 30. AddLiquidity: Single asset add liquidity (eg. Stargate)
  event AddLiquiditySingle(address fundAddress, address asset, address liquidityPool, uint256 amount, uint256 time);
  // 31. RemoveLiquidity: Single asset remove liquidity (eg. Stargate)
  event RemoveLiquiditySingle(address fundAddress, address asset, address liquidityPool, uint256 amount, uint256 time);
  // 32. Redeem Deprecated Synths into sUSD
  event SynthRedeem(address poolAddress, IERC20[] synthProxies);
  // 33. Synthetix V3 transactions
  event SynthetixV3Event(address poolLogic, uint256 txType);
  // 34. Sonne: Mint
  event SonneMintEvent(address indexed fundAddress, address asset, address cToken, uint256 amount, uint256 time);
  // 35. Sonne: Redeem
  event SonneRedeemEvent(address indexed fundAddress, address asset, address cToken, uint256 amount, uint256 time);
  // 36. Sonne: Redeem Underlying
  event SonneRedeemUnderlyingEvent(
    address indexed fundAddress,
    address asset,
    address cToken,
    uint256 amount,
    uint256 time
  );
  // 37. Sonne: Borrow
  event SonneBorrowEvent(address indexed fundAddress, address asset, address cToken, uint256 amount, uint256 time);
  // 38. Sonne: Repay
  event SonneRepayEvent(address indexed fundAddress, address asset, address cToken, uint256 amount, uint256 time);
  // 39. Sonne: Comptroller Enter Markets
  event SonneEnterMarkets(address indexed poolLogic, address[] cTokens, uint256 time);
  // 40. Sonne: Comptroller Exit Market
  event SonneExitMarket(address indexed poolLogic, address cToken, uint256 time);

  // Enum representing Transaction Types
  enum TransactionType {
    NotUsed, // 0
    Approve, // 1
    Exchange, // 2
    AddLiquidity, // 3
    RemoveLiquidity, // 4
    Stake, // 5
    Unstake, // 6
    Claim, // 7
    UnstakeAndClaim, // 8
    AaveDeposit, // 9
    AaveWithdraw, // 10
    AaveSetUserUseReserveAsCollateral, // 11
    AaveBorrow, // 12
    AaveRepay, // 13
    AaveSwapBorrowRateMode, // 14
    AaveRebalanceStableBorrowRate, // 15
    BalancerJoinPool, // 16
    BalancerExitPool, // 17
    EasySwapperDeposit, // 18
    EasySwapperWithdraw, // 19
    UniswapV3Mint, // 20
    UniswapV3IncreaseLiquidity, // 21
    UniswapV3DecreaseLiquidity, // 22
    UniswapV3Burn, // 23
    UniswapV3Collect, // 24
    UniswapV3Multicall, // 25
    LyraOpenPosition, // 26
    LyraClosePosition, // 27
    LyraForceClosePosition, // 28
    KwentaFuturesMarket, // 29
    AddLiquiditySingle, // 30
    RemoveLiquiditySingle, // 31
    MaiTx, // 32
    LyraAddCollateral, // 33
    LyraLiquidatePosition, // 34
    KwentaPerpsV2Market, // 35
    RedeemSynth, // 36
    SynthetixV3CreateAccount, // 37
    SynthetixV3DepositCollateral, // 38
    SynthetixV3WithdrawCollateral, // 39
    SynthetixV3DelegateCollateral, // 40
    SynthetixV3MintUSD, // 41
    SynthetixV3BurnUSD, // 42
    SynthetixV3Multicall, // 43
    XRamCreateVest, // 44
    XRamExitVest, // 45
    SynthetixV3Wrap, // 46
    SynthetixV3Unwrap, // 47
    SynthetixV3BuySynth, // 48
    SynthetixV3SellSynth, // 49
    SonneMint, // 50
    SonneRedeem, // 51
    SonneRedeemUnderlying, // 52
    SonneBorrow, // 53
    SonneRepay, // 54
    SonneComptrollerEnterMarkets, // 55
    SonneComptrollerExitMarket, // 56
    SynthetixV3UndelegateCollateral, // 57
    AaveMigrateToV3, // 58
    FlatMoneyStableDeposit, // 59
    FlatMoneyStableWithdraw, // 60
    FlatMoneyCancelOrder, // 61
    SynthetixV3ClaimReward, // 62
    VelodromeCLStake, // 63
    VelodromeCLUnstake, // 64
    VelodromeCLMint, // 65
    VelodromeCLIncreaseLiquidity, // 66
    VelodromeCLDecreaseLiquidity, // 67
    VelodromeCLBurn, // 68
    VelodromeCLCollect, // 69
    VelodromeCLMulticall, // 70
    FlatMoneyLeverageOpen, // 71
    FlatMoneyLeverageAdjust, // 72
    FlatMoneyLeverageClose // 73
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Module for atomic buy and sell orders for traders.
 */
interface IAtomicOrderModule {
  struct OrderFees {
    uint256 fixedFees;
    uint256 utilizationFees;
    int256 skewFees;
    int256 wrapperFees;
  }

  /**
   * @notice Initiates a buy trade returning synth for the specified amountUsd.
   * @dev Transfers the specified amountUsd, collects fees through configured fee collector, returns synth to the trader.
   * @dev Leftover fees not collected get deposited into the market manager to improve market PnL.
   * @dev Uses the buyFeedId configured for the market.
   * @param synthMarketId Id of the market used for the trade.
   * @param amountUsd Amount of snxUSD trader is providing allowance for the trade.
   * @param minAmountReceived Min Amount of synth is expected the trader to receive otherwise the transaction will revert.
   * @param referrer Optional address of the referrer, for fee share
   * @return synthAmount Synth received on the trade based on amount provided by trader.
   * @return fees breakdown of all the fees incurred for the transaction.
   */
  function buyExactIn(
    uint128 synthMarketId,
    uint256 amountUsd,
    uint256 minAmountReceived,
    address referrer
  ) external returns (uint256 synthAmount, OrderFees memory fees);

  /**
   * @notice  alias for buyExactIn
   * @param   marketId  (see buyExactIn)
   * @param   usdAmount  (see buyExactIn)
   * @param   minAmountReceived  (see buyExactIn)
   * @param   referrer  (see buyExactIn)
   * @return  synthAmount  (see buyExactIn)
   * @return  fees  (see buyExactIn)
   */
  function buy(
    uint128 marketId,
    uint256 usdAmount,
    uint256 minAmountReceived,
    address referrer
  ) external returns (uint256 synthAmount, OrderFees memory fees);

  /**
   * @notice Initiates a sell trade returning snxUSD for the specified amount of synth (sellAmount)
   * @dev Transfers the specified synth, collects fees through configured fee collector, returns snxUSD to the trader.
   * @dev Leftover fees not collected get deposited into the market manager to improve market PnL.
   * @param synthMarketId Id of the market used for the trade.
   * @param sellAmount Amount of synth provided by trader for trade into snxUSD.
   * @param minAmountReceived Min Amount of snxUSD trader expects to receive for the trade
   * @param referrer Optional address of the referrer, for fee share
   * @return returnAmount Amount of snxUSD returned to user
   * @return fees breakdown of all the fees incurred for the transaction.
   */
  function sellExactIn(
    uint128 synthMarketId,
    uint256 sellAmount,
    uint256 minAmountReceived,
    address referrer
  ) external returns (uint256 returnAmount, OrderFees memory fees);

  /**
   * @notice  alias for sellExactIn
   * @param   marketId  (see sellExactIn)
   * @param   synthAmount  (see sellExactIn)
   * @param   minUsdAmount  (see sellExactIn)
   * @param   referrer  (see sellExactIn)
   * @return  usdAmountReceived  (see sellExactIn)
   * @return  fees  (see sellExactIn)
   */
  function sell(
    uint128 marketId,
    uint256 synthAmount,
    uint256 minUsdAmount,
    address referrer
  ) external returns (uint256 usdAmountReceived, OrderFees memory fees);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Module for spot market factory
 */
interface ISpotMarketFactoryModule {
  /**
   * @notice Get the proxy address of the synth for the provided marketId
   * @dev Uses associated systems module to retrieve the token address.
   * @param marketId id of the market
   * @return synthAddress address of the proxy for the synth
   */
  function getSynth(uint128 marketId) external view returns (address synthAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../../utils/synthetixV3/libraries/SynthetixV3Structs.sol";

interface ISynthetixV3ContractGuard {
  function dHedgeVaultsWhitelist(address _poolLogic) external view returns (SynthetixV3Structs.VaultSetting memory);

  function getAccountNftTokenId(address _poolLogic, address _to) external view returns (uint128 tokenId);

  function isVaultWhitelisted(address _poolLogic) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Module for synth wrappers
 */
interface IWrapperModule {
  struct OrderFees {
    uint256 fixedFees;
    uint256 utilizationFees;
    int256 skewFees;
    int256 wrapperFees;
  }

  /**
   * @notice Wraps the specified amount and returns similar value of synth minus the fees.
   * @dev Fees are collected from the user by way of the contract returning less synth than specified amount of collateral.
   * @param marketId Id of the market used for the trade.
   * @param wrapAmount Amount of collateral to wrap.  This amount gets deposited into the market collateral manager.
   * @param minAmountReceived The minimum amount of synths the trader is expected to receive, otherwise the transaction will revert.
   * @return amountToMint Amount of synth returned to user.
   * @return fees breakdown of all fees. in this case, only wrapper fees are returned.
   */
  function wrap(
    uint128 marketId,
    uint256 wrapAmount,
    uint256 minAmountReceived
  ) external returns (uint256 amountToMint, OrderFees memory fees);

  /**
   * @notice Unwraps the synth and returns similar value of collateral minus the fees.
   * @dev Transfers the specified synth, collects fees through configured fee collector, returns collateral minus fees to trader.
   * @param marketId Id of the market used for the trade.
   * @param unwrapAmount Amount of synth trader is unwrapping.
   * @param minAmountReceived The minimum amount of collateral the trader is expected to receive, otherwise the transaction will revert.
   * @return returnCollateralAmount Amount of collateral returned.
   * @return fees breakdown of all fees. in this case, only wrapper fees are returned.
   */
  function unwrap(
    uint128 marketId,
    uint256 unwrapAmount,
    uint256 minAmountReceived
  ) external returns (uint256 returnCollateralAmount, OrderFees memory fees);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {IERC20Extended} from "../interfaces/IERC20Extended.sol";

library PrecisionHelper {
  function getPrecisionForConversion(address _token) internal view returns (uint256 precision) {
    precision = 10 ** (18 - (IERC20Extended(_token).decimals()));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library SynthetixV3Structs {
  struct VaultSetting {
    address poolLogic;
    address collateralAsset;
    address debtAsset;
    uint128 snxLiquidityPoolId;
  }

  /// @dev Couldn't find a way to get a mapping from synthAddress to its markedId, so storing it in guard's storage
  /// @dev Was looking for something like getSynth() but reversed
  struct AllowedMarket {
    uint128 marketId;
    address collateralSynth;
    address collateralAsset;
  }

  struct TimePeriod {
    uint8 dayOfWeek;
    uint8 hour;
  }

  struct Window {
    TimePeriod start;
    TimePeriod end;
  }

  struct WeeklyWindows {
    Window delegationWindow;
    Window undelegationWindow;
  }

  struct WeeklyWithdrawalLimit {
    uint256 usdValue;
    uint256 percent;
  }
}

//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@uniswap/v3-periphery/contracts/libraries/BytesLib.sol";

contract TxDataUtils {
  using BytesLib for bytes;
  using SafeMathUpgradeable for uint256;

  function getMethod(bytes memory data) public pure returns (bytes4) {
    return read4left(data, 0);
  }

  function getParams(bytes memory data) public pure returns (bytes memory) {
    return data.slice(4, data.length - 4);
  }

  function getInput(bytes memory data, uint8 inputNum) public pure returns (bytes32) {
    return read32(data, 32 * inputNum + 4, 32);
  }

  function getBytes(bytes memory data, uint8 inputNum, uint256 offset) public pure returns (bytes memory) {
    require(offset < 20, "invalid offset"); // offset is in byte32 slots, not bytes
    offset = offset * 32; // convert offset to bytes
    uint256 bytesLenPos = uint256(read32(data, 32 * inputNum + 4 + offset, 32));
    uint256 bytesLen = uint256(read32(data, bytesLenPos + 4 + offset, 32));
    return data.slice(bytesLenPos + 4 + offset + 32, bytesLen);
  }

  function getArrayLast(bytes memory data, uint8 inputNum) public pure returns (bytes32) {
    bytes32 arrayPos = read32(data, 32 * inputNum + 4, 32);
    bytes32 arrayLen = read32(data, uint256(arrayPos) + 4, 32);
    require(arrayLen > 0, "input is not array");
    return read32(data, uint256(arrayPos) + 4 + (uint256(arrayLen) * 32), 32);
  }

  function getArrayLength(bytes memory data, uint8 inputNum) public pure returns (uint256) {
    bytes32 arrayPos = read32(data, 32 * inputNum + 4, 32);
    return uint256(read32(data, uint256(arrayPos) + 4, 32));
  }

  function getArrayIndex(bytes memory data, uint8 inputNum, uint8 arrayIndex) public pure returns (bytes32) {
    bytes32 arrayPos = read32(data, 32 * inputNum + 4, 32);
    bytes32 arrayLen = read32(data, uint256(arrayPos) + 4, 32);
    require(arrayLen > 0, "input is not array");
    require(uint256(arrayLen) > arrayIndex, "invalid array position");
    return read32(data, uint256(arrayPos) + 4 + ((1 + uint256(arrayIndex)) * 32), 32);
  }

  function read4left(bytes memory data, uint256 offset) public pure returns (bytes4 o) {
    require(data.length >= offset + 4, "Reading bytes out of bounds");
    assembly {
      o := mload(add(data, add(32, offset)))
    }
  }

  function read32(bytes memory data, uint256 offset, uint256 length) public pure returns (bytes32 o) {
    require(data.length >= offset + length, "Reading bytes out of bounds");
    assembly {
      o := mload(add(data, add(32, offset)))
      let lb := sub(32, length)
      if lb {
        o := div(o, exp(2, mul(lb, 8)))
      }
    }
  }

  function convert32toAddress(bytes32 data) public pure returns (address o) {
    return address(uint160(uint256(data)));
  }

  function sliceUint(bytes memory data, uint256 start) internal pure returns (uint256) {
    require(data.length >= start + 32, "slicing out of range");
    uint256 x;
    assembly {
      x := mload(add(data, add(0x20, start)))
    }
    return x;
  }
}