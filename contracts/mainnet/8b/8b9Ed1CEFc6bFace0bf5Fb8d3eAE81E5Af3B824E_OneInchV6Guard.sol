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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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

import {IGuard} from "../../interfaces/guards/IGuard.sol";
import {IAggregationRouterV6} from "../../interfaces/oneInch/IAggregationRouterV6.sol";
import {IUniswapV3Pool} from "../../interfaces/uniswapV3/IUniswapV3Pool.sol";
import {IHasSupportedAsset} from "../../interfaces/IHasSupportedAsset.sol";
import {IPoolManagerLogic} from "../../interfaces/IPoolManagerLogic.sol";
import {ITransactionTypes} from "../../interfaces/ITransactionTypes.sol";
import {AddressLib} from "../../utils/oneInch/libraries/AddressLib.sol";
import {ProtocolLib} from "../../utils/oneInch/libraries/ProtocolLib.sol";
import {SlippageAccumulator} from "../../utils/SlippageAccumulator.sol";
import {TxDataUtils} from "../../utils/TxDataUtils.sol";

/// @notice Contract guard contract for 1inch AggregationRouterV6
contract OneInchV6Guard is IGuard, TxDataUtils, ITransactionTypes {
  using AddressLib for uint256;
  using ProtocolLib for uint256;

  SlippageAccumulator private immutable slippageAccumulator;

  constructor(address _slippageAccumulator) {
    require(_slippageAccumulator != address(0), "invalid address");

    slippageAccumulator = SlippageAccumulator(_slippageAccumulator);
  }

  /// @dev Doesn't support methods `unoswapTo, `unoswapTo2`, `unoswapTo3`, `clipperSwapTo`,
  ///      not sure yet if having them is necessary.
  /// @param _poolManagerLogic Pool manager logic address
  /// @param _to 1inch AggregationRouterV6 address
  /// @param _data Transaction data
  /// @return txType Transaction type
  /// @return isPublic If the transaction is public or private
  function txGuard(
    address _poolManagerLogic,
    address _to,
    bytes memory _data
  ) external override returns (uint16 txType, bool) {
    IPoolManagerLogic poolManagerLogic = IPoolManagerLogic(_poolManagerLogic);
    address poolLogic = poolManagerLogic.poolLogic();

    require(msg.sender == poolLogic, "not pool logic");

    bytes4 method = getMethod(_data);
    bytes memory params = getParams(_data);

    SlippageAccumulator.SwapData memory swapData;
    swapData.to = _to;
    swapData.poolManagerLogic = _poolManagerLogic;

    if (method == IAggregationRouterV6.swap.selector) {
      (, IAggregationRouterV6.SwapDescription memory description) = abi.decode(
        params,
        (address, IAggregationRouterV6.SwapDescription)
      );

      require(description.dstReceiver == poolLogic, "recipient is not pool");

      swapData.srcAsset = description.srcToken;
      swapData.dstAsset = description.dstToken;
      swapData.srcAmount = description.amount;
      swapData.dstAmount = description.minReturnAmount;

      txType = _verifySwap(swapData);
    } else if (method == IAggregationRouterV6.unoswap.selector) {
      (uint256 srcToken, uint256 srcAmount, uint256 dstAmount, uint256 pool) = abi.decode(
        params,
        (uint256, uint256, uint256, uint256)
      );
      swapData.srcAsset = srcToken.get();

      uint256[] memory pools = new uint256[](1);
      pools[0] = pool;
      _checkProtocolsSupported(pools);

      swapData.dstAsset = _retreiveDstToken(swapData.srcAsset, pools);
      swapData.srcAmount = srcAmount;
      swapData.dstAmount = dstAmount;

      txType = _verifySwap(swapData);
    } else if (method == IAggregationRouterV6.unoswap2.selector) {
      (uint256 srcToken, uint256 srcAmount, uint256 dstAmount, uint256 pool1, uint256 pool2) = abi.decode(
        params,
        (uint256, uint256, uint256, uint256, uint256)
      );
      swapData.srcAsset = srcToken.get();

      uint256[] memory pools = new uint256[](2);
      pools[0] = pool1;
      pools[1] = pool2;
      _checkProtocolsSupported(pools);

      swapData.dstAsset = _retreiveDstToken(swapData.srcAsset, pools);
      swapData.srcAmount = srcAmount;
      swapData.dstAmount = dstAmount;

      txType = _verifySwap(swapData);
    } else if (method == IAggregationRouterV6.unoswap3.selector) {
      (uint256 srcToken, uint256 srcAmount, uint256 dstAmount, uint256 pool1, uint256 pool2, uint256 pool3) = abi
        .decode(params, (uint256, uint256, uint256, uint256, uint256, uint256));
      swapData.srcAsset = srcToken.get();

      uint256[] memory pools = new uint256[](3);
      pools[0] = pool1;
      pools[1] = pool2;
      pools[2] = pool3;
      _checkProtocolsSupported(pools);

      swapData.dstAsset = _retreiveDstToken(swapData.srcAsset, pools);
      swapData.srcAmount = srcAmount;
      swapData.dstAmount = dstAmount;

      txType = _verifySwap(swapData);
    }

    return (txType, false);
  }

  function _verifySwap(SlippageAccumulator.SwapData memory _swapData) internal returns (uint16 txType) {
    require(
      IHasSupportedAsset(_swapData.poolManagerLogic).isSupportedAsset(_swapData.dstAsset),
      "unsupported destination asset"
    );

    slippageAccumulator.updateSlippageImpact(_swapData);

    txType = uint16(TransactionType.Exchange);
  }

  function _retreiveDstToken(address _srcToken, uint256[] memory _pools) internal view returns (address dstToken) {
    dstToken = _srcToken;
    for (uint8 i = 0; i < _pools.length; i++) {
      IUniswapV3Pool pool = IUniswapV3Pool(_pools[i].get());
      address token0 = pool.token0();
      address token1 = pool.token1();
      if (dstToken == token0) {
        dstToken = token1;
      } else if (dstToken == token1) {
        dstToken = token0;
      } else {
        revert("invalid path");
      }
    }
  }

  function _checkProtocolsSupported(uint256[] memory _pools) internal pure {
    for (uint256 i = 0; i < _pools.length; i++) {
      ProtocolLib.Protocol protocol = _pools[i].protocol();
      require(
        protocol == ProtocolLib.Protocol.UniswapV2 || protocol == ProtocolLib.Protocol.UniswapV3,
        "exchange pool not supported"
      );
      require(!_pools[i].shouldUnwrapWeth(), "WETH unwrap not supported");
    }
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

pragma solidity >=0.7.6 <=0.8.10;

interface IHasAssetInfo {
  function isValidAsset(address asset) external view returns (bool);

  function getAssetPrice(address asset) external view returns (uint256);

  function getAssetType(address asset) external view returns (uint16);

  function getMaximumSupportedAssetCount() external view returns (uint256);
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

pragma experimental ABIEncoderV2;

interface IHasSupportedAsset {
  struct Asset {
    address asset;
    bool isDeposit;
  }

  function getSupportedAssets() external view returns (Asset[] memory);

  function isSupportedAsset(address asset) external view returns (bool);
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

interface IPoolFactory {
  function governanceAddress() external view returns (address);

  function isPool(address pool) external view returns (bool);

  function customCooldownWhitelist(address from) external view returns (bool);

  function receiverWhitelist(address to) external view returns (bool);

  function emitPoolEvent() external;

  function emitPoolManagerEvent() external;
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

/// @title Interface for making arbitrary calls during swap
interface IAggregationExecutor {
  /// @notice propagates information about original msg.sender and executes arbitrary data
  function execute(address msgSender) external payable returns (uint256); // 0x4b64e492
}

/// @title Clipper interface subset used in swaps
interface IClipperExchange {
  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  function sellEthForToken(
    address outputToken,
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    address destinationAddress,
    Signature calldata theSignature,
    bytes calldata auxiliaryData
  ) external payable;

  function sellTokenForEth(
    address inputToken,
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    address destinationAddress,
    Signature calldata theSignature,
    bytes calldata auxiliaryData
  ) external;

  function swap(
    address inputToken,
    address outputToken,
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    address destinationAddress,
    Signature calldata theSignature,
    bytes calldata auxiliaryData
  ) external;
}

interface IAggregationRouterV6 {
  struct SwapDescription {
    address srcToken; // IERC20
    address dstToken; // IERC20
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
  }

  /**
   * @notice Performs a swap, delegating all calls encoded in `data` to `executor`. See tests for usage examples.
   * @dev Router keeps 1 wei of every token on the contract balance for gas optimisations reasons.
   *      This affects first swap of every token by leaving 1 wei on the contract.
   * @param executor Aggregation executor that executes calls described in `data`.
   * @param desc Swap description.
   * @param data Encoded calls that `caller` should execute in between of swaps.
   * @return returnAmount Resulting token amount.
   * @return spentAmount Source token amount.
   */
  function swap(
    IAggregationExecutor executor,
    SwapDescription calldata desc,
    bytes calldata data
  ) external payable returns (uint256 returnAmount, uint256 spentAmount);

  /**
   * @notice Swaps `amount` of the specified `token` for another token using an Unoswap-compatible exchange's pool,
   *         with a minimum return specified by `minReturn`.
   * @param token The address of the token to be swapped.
   * @param amount The amount of tokens to be swapped.
   * @param minReturn The minimum amount of tokens to be received after the swap.
   * @param dex The address of the Unoswap-compatible exchange's pool.
   * @return returnAmount The actual amount of tokens received after the swap.
   */
  function unoswap(
    uint256 token, // Address
    uint256 amount,
    uint256 minReturn,
    uint256 dex // Address
  ) external returns (uint256 returnAmount);

  /**
   * @notice Swaps `amount` of the specified `token` for another token using two Unoswap-compatible exchange pools (`dex` and `dex2`) sequentially,
   *         with a minimum return specified by `minReturn`.
   * @param token The address of the token to be swapped.
   * @param amount The amount of tokens to be swapped.
   * @param minReturn The minimum amount of tokens to be received after the swap.
   * @param dex The address of the first Unoswap-compatible exchange's pool.
   * @param dex2 The address of the second Unoswap-compatible exchange's pool.
   * @return returnAmount The actual amount of tokens received after the swap through both pools.
   */
  function unoswap2(
    uint256 token, // Address
    uint256 amount,
    uint256 minReturn,
    uint256 dex, // Address
    uint256 dex2 // Address
  ) external returns (uint256 returnAmount);

  /**
   * @notice Swaps `amount` of the specified `token` for another token using three Unoswap-compatible exchange pools
   *         (`dex`, `dex2`, and `dex3`) sequentially, with a minimum return specified by `minReturn`.
   * @param token The address of the token to be swapped.
   * @param amount The amount of tokens to be swapped.
   * @param minReturn The minimum amount of tokens to be received after the swap.
   * @param dex The address of the first Unoswap-compatible exchange's pool.
   * @param dex2 The address of the second Unoswap-compatible exchange's pool.
   * @param dex3 The address of the third Unoswap-compatible exchange's pool.
   * @return returnAmount The actual amount of tokens received after the swap through all three pools.
   */
  function unoswap3(
    uint256 token, // Address
    uint256 amount,
    uint256 minReturn,
    uint256 dex, // Address
    uint256 dex2, // Address
    uint256 dex3 // Address
  ) external returns (uint256 returnAmount);

  /**
   * @notice Same as `clipperSwapTo` but uses `msg.sender` as recipient.
   * @param clipperExchange Clipper pool address.
   * @param srcToken Source token and flags.
   * @param dstToken Destination token.
   * @param inputAmount Amount of source tokens to swap.
   * @param outputAmount Amount of destination tokens to receive.
   * @param goodUntil Clipper parameter.
   * @param r Clipper order signature (r part).
   * @param vs Clipper order signature (vs part).
   * @return returnAmount Amount of destination tokens received.
   */
  function clipperSwap(
    IClipperExchange clipperExchange,
    uint256 srcToken, // Address
    address dstToken, // IERC20
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    bytes32 r,
    bytes32 vs
  ) external payable returns (uint256 returnAmount);

  /**
   * @notice Swaps `amount` of the specified `token` for another token using an Unoswap-compatible exchange's pool,
   *         sending the resulting tokens to the `to` address, with a minimum return specified by `minReturn`.
   * @param to The address to receive the swapped tokens.
   * @param token The address of the token to be swapped.
   * @param amount The amount of tokens to be swapped.
   * @param minReturn The minimum amount of tokens to be received after the swap.
   * @param dex The address of the Unoswap-compatible exchange's pool.
   * @return returnAmount The actual amount of tokens received after the swap.
   */
  function unoswapTo(
    uint256 to, // Address
    uint256 token, // Address
    uint256 amount,
    uint256 minReturn,
    uint256 dex // Address
  ) external returns (uint256 returnAmount);

  /**
   * @notice Swaps `amount` of the specified `token` for another token using two Unoswap-compatible exchange pools (`dex` and `dex2`) sequentially,
   *         sending the resulting tokens to the `to` address, with a minimum return specified by `minReturn`.
   * @param to The address to receive the swapped tokens.
   * @param token The address of the token to be swapped.
   * @param amount The amount of tokens to be swapped.
   * @param minReturn The minimum amount of tokens to be received after the swap.
   * @param dex The address of the first Unoswap-compatible exchange's pool.
   * @param dex2 The address of the second Unoswap-compatible exchange's pool.
   * @return returnAmount The actual amount of tokens received after the swap through both pools.
   */
  function unoswapTo2(
    uint256 to, // Address
    uint256 token, // Address
    uint256 amount,
    uint256 minReturn,
    uint256 dex, // Address
    uint256 dex2 // Address
  ) external returns (uint256 returnAmount);

  /**
   * @notice Swaps `amount` of the specified `token` for another token using three Unoswap-compatible exchange pools
   *         (`dex`, `dex2`, and `dex3`) sequentially, sending the resulting tokens to the `to` address, with a minimum return specified by `minReturn`.
   * @param to The address to receive the swapped tokens.
   * @param token The address of the token to be swapped.
   * @param amount The amount of tokens to be swapped.
   * @param minReturn The minimum amount of tokens to be received after the swap.
   * @param dex The address of the first Unoswap-compatible exchange's pool.
   * @param dex2 The address of the second Unoswap-compatible exchange's pool.
   * @param dex3 The address of the third Unoswap-compatible exchange's pool.
   * @return returnAmount The actual amount of tokens received after the swap through all three pools.
   */
  function unoswapTo3(
    uint256 to, // Address
    uint256 token, // Address
    uint256 amount,
    uint256 minReturn,
    uint256 dex, // Address
    uint256 dex2, // Address
    uint256 dex3 // Address
  ) external returns (uint256 returnAmount);

  /**
   * @notice Performs swap using Clipper exchange. Wraps and unwraps ETH if required.
   *         Sending non-zero `msg.value` for anything but ETH swaps is prohibited.
   * @param clipperExchange Clipper pool address.
   * @param recipient Address that will receive swap funds.
   * @param srcToken Source token and flags.
   * @param dstToken Destination token.
   * @param inputAmount Amount of source tokens to swap.
   * @param outputAmount Amount of destination tokens to receive.
   * @param goodUntil Clipper parameter.
   * @param r Clipper order signature (r part).
   * @param vs Clipper order signature (vs part).
   * @return returnAmount Amount of destination tokens received.
   */
  function clipperSwapTo(
    IClipperExchange clipperExchange,
    address payable recipient,
    uint256 srcToken, // Address
    address dstToken, // IERC20
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    bytes32 r,
    bytes32 vs
  ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

interface IUniswapV3Pool {
  function token0() external view returns (address);

  function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @dev Library for working with addresses encoded as uint256 values, which can include flags in the highest bits.
 *      Taken from 1inch AggregationRouterV6 contract, rest of the library can be found there.
 */
library AddressLib {
  uint256 private constant _LOW_160_BIT_MASK = (1 << 160) - 1;

  /**
   * @notice Returns the address representation of a uint256.
   * @param a The uint256 value to convert to an address.
   * @return The address representation of the provided uint256 value.
   */
  function get(uint256 a) internal pure returns (address) {
    return address(uint160(a & _LOW_160_BIT_MASK));
  }

  /**
   * @notice Checks if a given flag is set for the provided address.
   * @param a The address to check for the flag.
   * @param flag The flag to check for in the provided address.
   * @return True if the provided flag is set in the address, false otherwise.
   */
  function getFlag(uint256 a, uint256 flag) internal pure returns (bool) {
    return (a & flag) != 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {AddressLib} from "./AddressLib.sol";

/**
 * @dev Taken from 1inch AggregationRouterV6 contract, rest of the library can be found there.
 */
library ProtocolLib {
  using AddressLib for uint256;

  enum Protocol {
    UniswapV2,
    UniswapV3,
    Curve
  }

  uint256 private constant _PROTOCOL_OFFSET = 253;
  uint256 private constant _WETH_UNWRAP_FLAG = 1 << 252;

  function protocol(uint256 self) internal pure returns (Protocol) {
    // there is no need to mask because protocol is stored in the highest 3 bits
    return Protocol((self >> _PROTOCOL_OFFSET));
  }

  function shouldUnwrapWeth(uint256 self) internal pure returns (bool) {
    return self.getFlag(_WETH_UNWRAP_FLAG);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "../interfaces/IERC20Extended.sol";
import "../interfaces/IPoolManagerLogic.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IHasSupportedAsset.sol";
import "../interfaces/IHasAssetInfo.sol";
import "../interfaces/IHasGuardInfo.sol";

/// @title SlippageAccumulator
/// @notice Contract to check for accumulated slippage impact for a poolManager.
/// @author dHEDGE
contract SlippageAccumulator is Ownable {
  using SafeMathUpgradeable for *;
  using Math for *;
  using SafeCast for *;

  /// @dev Struct for passing swap related data to the slippage accumulator function.
  /// @param srcAsset Source asset (asset to be exchanged).
  /// @param dstAsset Destination asset (asset being exchanged for).
  /// @param srcAmount Source asset amount.
  /// @param dstAmount Destination asset amount.
  /// @param to Address of the external contract used for swapping.
  /// @param poolManagerLogic The poolManager contract address performing the swap.
  struct SwapData {
    address srcAsset;
    address dstAsset;
    uint256 srcAmount;
    uint256 dstAmount;
    address to;
    address poolManagerLogic;
  }

  /// @dev Struct to track the slippage data for a poolManager.
  /// @param lastTradeTimestamp Last successful trade's timestamp.
  /// @param accumulatedSlippage The accumulated slippage impact of a poolManager.
  struct ManagerSlippageData {
    uint64 lastTradeTimestamp;
    uint128 accumulatedSlippage;
  }

  event DecayTimeChanged(uint64 oldDecayTime, uint64 newDecayTime);
  event MaxCumulativeSlippageChanged(uint128 oldMaxCumulativeSlippage, uint128 newMaxCumulativeSlippage);

  /// @dev Constant used to multiply the slippage loss percentage with 4 decimal precision.
  uint128 private constant SCALING_FACTOR = 1e6;

  /// @dev dHEDGE poolFactory address.
  address private immutable poolFactory;

  /// @notice Maximum acceptable cumulative trade slippage impact within a period of time (upto 4 decimal precision).
  /// @dev Eg. 5% = 5e4
  uint128 public maxCumulativeSlippage;

  /// @notice Price accumulator decay time.
  /// @dev Eg 6 hours = 21600.
  uint64 public decayTime;

  /// @notice Tracks the last trade timestamp and accumulated slippage for each poolManager.
  mapping(address => ManagerSlippageData) public managerData;

  /// @dev Modifier to make sure caller is a contract guard.
  modifier onlyContractGuard(address to) {
    address contractGuard = IHasGuardInfo(poolFactory).getContractGuard(to);

    require(contractGuard == msg.sender, "Not authorised guard");
    _;
  }

  constructor(address _poolFactory, uint64 _decayTime, uint128 _maxCumulativeSlippage) {
    require(_poolFactory != address(0), "Null address");

    poolFactory = _poolFactory;
    decayTime = _decayTime;
    maxCumulativeSlippage = _maxCumulativeSlippage;
  }

  /// @notice Updates the cumulative slippage impact and reverts if it's beyond limit.
  /// @dev NOTE: It's important that the calling guard checks if the msg.sender in it's scope is authorised.
  /// @dev If the caller is not checked for in the guard, anyone can trigger the `txGuard` transaction and update slippage impact.
  /// @param swapData Common swap data for all guards.
  function updateSlippageImpact(SwapData calldata swapData) external onlyContractGuard(swapData.to) {
    if (IHasSupportedAsset(swapData.poolManagerLogic).isSupportedAsset(swapData.srcAsset)) {
      uint256 srcAmount = _assetValue(swapData.srcAsset, swapData.srcAmount);
      uint256 dstAmount = _assetValue(swapData.dstAsset, swapData.dstAmount);

      // Only update the cumulative slippage in case the amount received is lesser than amount sent/traded.
      if (dstAmount < srcAmount) {
        uint128 newSlippage = srcAmount.sub(dstAmount).mul(SCALING_FACTOR).div(srcAmount).toUint128();

        uint128 newCumulativeSlippage = (
          uint256(newSlippage).add(getCumulativeSlippageImpact(swapData.poolManagerLogic))
        ).toUint128();

        require(newCumulativeSlippage < maxCumulativeSlippage, "slippage impact exceeded");

        // Update the last traded timestamp.
        managerData[swapData.poolManagerLogic].lastTradeTimestamp = (block.timestamp).toUint64();

        // Update the accumulated slippage impact for the poolManager.
        managerData[swapData.poolManagerLogic].accumulatedSlippage = newCumulativeSlippage;
      }
    }
  }

  /// Function to calculate an asset amount's value in usd.
  /// @param asset The asset whose price oracle exists.
  /// @param amount The amount of the `asset`.
  function _assetValue(address asset, uint256 amount) internal view returns (uint256 value) {
    value = amount.mul(IHasAssetInfo(poolFactory).getAssetPrice(asset)).div(10 ** IERC20Extended(asset).decimals()); // to USD amount
  }

  /// @notice Function to get the cumulative slippage adjusted using decayTime (current cumulative slippage impact).
  /// @param poolManagerLogic Address of the poolManager whose cumulative impact is stored.
  function getCumulativeSlippageImpact(address poolManagerLogic) public view returns (uint128 cumulativeSlippage) {
    ManagerSlippageData memory managerSlippageData = managerData[poolManagerLogic];

    return
      (
        uint256(managerSlippageData.accumulatedSlippage)
          .mul(decayTime.sub(decayTime.min(block.timestamp.sub(managerSlippageData.lastTradeTimestamp))))
          .div(decayTime)
      ).toUint128();
  }

  /**********************************************
   *             Owner Functions                *
   *********************************************/

  /// @notice Function to change decay time for calculating price impact.
  /// @param newDecayTime The new decay time (in seconds).
  function setDecayTime(uint64 newDecayTime) external onlyOwner {
    uint64 oldDecayTime = decayTime;

    decayTime = newDecayTime;

    emit DecayTimeChanged(oldDecayTime, newDecayTime);
  }

  /// @notice Function to change the max acceptable cumulative slippage impact.
  /// @param newMaxCumulativeSlippage The new max acceptable cumulative slippage impact.
  function setMaxCumulativeSlippage(uint128 newMaxCumulativeSlippage) external onlyOwner {
    uint128 oldMaxCumulativeSlippage = maxCumulativeSlippage;

    maxCumulativeSlippage = newMaxCumulativeSlippage;

    emit MaxCumulativeSlippageChanged(oldMaxCumulativeSlippage, newMaxCumulativeSlippage);
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