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
pragma abicoder v2;

import "../../utils/TxDataUtils.sol";
import "../../interfaces/guards/IAssetGuard.sol";
import "../../interfaces/guards/IGuard.sol";

// This should be the base for all AssetGuards that are not ERC20 or are ERC20 but should not be transferrable
abstract contract ClosedAssetGuard is TxDataUtils, IGuard, IAssetGuard {
  /// @notice Doesn't allow any transactions uses separate contract guard that should be migrated here
  /// @dev Parses the manager transaction data to ensure transaction is valid
  /// @return txType transaction type described in PoolLogic
  /// @return isPublic if the transaction is public or private
  function txGuard(
    address,
    address,
    bytes calldata
  )
    external
    pure
    virtual
    override
    returns (
      uint16 txType, // transaction type
      bool // isPublic
    )
  {
    return (txType, false);
  }

  /// @notice Returns the balance of the managed asset
  /// @dev May include any external balance in staking contracts
  /// @return balance The asset balance of given pool for the given asset
  function getBalance(address, address) public view virtual override returns (uint256) {
    revert("not implemented");
  }

  /// @notice Necessary check for remove asset
  /// @param pool Address of the pool
  /// @param asset Address of the remove asset
  function removeAssetCheck(address pool, address asset) public view virtual override {
    uint256 balance = getBalance(pool, asset);
    require(balance == 0, "cannot remove non-empty asset");
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
// Copyright (c) 2023 dHEDGE DAO
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";

import {IMutableBalanceAssetGuard} from "../../../interfaces/guards/IMutableBalanceAssetGuard.sol";
import {ICollateralModule} from "../../../interfaces/synthetixV3/ICollateralModule.sol";
import {ILiquidationModule} from "../../../interfaces/synthetixV3/ILiquidationModule.sol";
import {ISynthetixV3ContractGuard} from "../../../interfaces/synthetixV3/ISynthetixV3ContractGuard.sol";
import {ISynthetixV3SpotMarketContractGuard} from "../../../interfaces/synthetixV3/ISynthetixV3SpotMarketContractGuard.sol";
import {IVaultModule} from "../../../interfaces/synthetixV3/IVaultModule.sol";
import {IWrapperModule} from "../../../interfaces/synthetixV3/IWrapperModule.sol";
import {IPoolLogic} from "../../../interfaces/IPoolLogic.sol";
import {IHasAssetInfo} from "../../../interfaces/IHasAssetInfo.sol";
import {IHasGuardInfo} from "../../../interfaces/IHasGuardInfo.sol";
import {IPoolManagerLogic} from "../../../interfaces/IPoolManagerLogic.sol";
import {SynthetixV3Structs} from "../../../utils/synthetixV3/libraries/SynthetixV3Structs.sol";
import {PrecisionHelper} from "../../../utils/PrecisionHelper.sol";
import {ClosedAssetGuard} from "../ClosedAssetGuard.sol";

contract SynthetixV3AssetGuard is ClosedAssetGuard, IMutableBalanceAssetGuard {
  using SafeMath for uint256;
  using SafeCast for int256;
  using PrecisionHelper for address;

  struct DebtRecord {
    int256 debt;
    uint256 timestamp;
  }

  struct WithdrawTxsParams {
    address snxV3Core;
    uint128 accountId;
    address collateralType;
    uint256 withdrawAmount;
    address to;
  }

  address public immutable snxSpotMarket;

  bool public override isStateMutatingGuard = true;

  mapping(address => DebtRecord) public latestDebtRecords;

  constructor(address _snxSpotMarket) {
    require(_snxSpotMarket != address(0), "invalid snxSpotMarket");

    snxSpotMarket = _snxSpotMarket;
  }

  /// @notice Returns the balance of Synthetix V3 position, accurate balance is not guaranteed
  /// @dev Returns the balance to be priced in USD
  /// @param _pool Pool address
  /// @param _asset Asset address (Basically Synthetix V3 core address)
  /// @return balance Synthetix V3 balance of the pool
  function getBalance(address _pool, address _asset) public view override returns (uint256) {
    (uint128 accountId, address collateralType, , address debtAsset) = _getPoolPositionDetails(_pool, _asset);

    // Using latest stored debt record to calculate balance
    return _calculateBalance(_pool, _asset, accountId, collateralType, debtAsset, latestDebtRecords[_pool].debt);
  }

  /// @notice Returns the balance of Synthetix V3 position in a mutable way
  /// @dev This is required due to getPositionDebt is a non-view function
  /// @dev Returns the balance to be priced in USD
  /// @param _pool Pool address
  /// @param _asset Asset address (Basically Synthetix V3 core address)
  /// @return balance Synthetix V3 balance of the pool
  function getBalanceMutable(address _pool, address _asset) public override returns (uint256) {
    (uint128 accountId, address collateralType, uint128 poolId, address debtAsset) = _getPoolPositionDetails(
      _pool,
      _asset
    );

    if (ILiquidationModule(_asset).isPositionLiquidatable(accountId, poolId, collateralType)) {
      ILiquidationModule(_asset).liquidate(accountId, poolId, collateralType, accountId);
    }

    // Getting position debt from Synthetix V3 system
    int256 debtD18 = IVaultModule(_asset).getPositionDebt(accountId, poolId, collateralType);
    // Storing latest debt record to be used in classic getBalance
    latestDebtRecords[_pool] = DebtRecord({debt: debtD18, timestamp: block.timestamp});

    return _calculateBalance(_pool, _asset, accountId, collateralType, debtAsset, debtD18);
  }

  /// @notice Returns the decimals of Synthetix V3 position
  /// @return decimals Decimals of the asset
  function getDecimals(address) external pure override returns (uint256 decimals) {
    decimals = 18;
  }

  /// @notice Creates transaction data for withdrawing from Synthetix V3 position
  /// @dev Current version is the simplest workaround of lockup issue
  /// @dev Assumes that the pool always holds some amount of undelegated collateral that can be withdrawn
  /// @dev That implies limitations on the size of the withdrawal
  /// @param _pool Pool address
  /// @param _asset Asset address (Basically Synthetix V3 core address)
  /// @param _withdrawPortion Portion of the asset to withdraw
  /// @param _to Investor address to withdraw to
  /// @return withdrawAsset Asset address to withdraw (Basically zero address)
  /// @return withdrawBalance Amount to withdraw (Basically zero amount)
  /// @return transactions Transactions to be executed (These is where actual token transfer happens)
  function withdrawProcessing(
    address _pool,
    address _asset,
    uint256 _withdrawPortion,
    address _to
  ) external override returns (address withdrawAsset, uint256 withdrawBalance, MultiTransaction[] memory transactions) {
    WithdrawTxsParams memory params;
    params.snxV3Core = _asset;
    params.to = _to;
    // Collecting data to perform withdrawal
    (params.accountId, params.collateralType, , ) = _getPoolPositionDetails(_pool, _asset);
    uint256 balance = getBalanceMutable(_pool, _asset);

    // My thinking this check is needed for the cases when pool enabled Synthetix V3 position, but never interacted with it or has nothing in it
    if (params.accountId == 0 || balance == 0) {
      return (address(0), 0, transactions);
    }

    // Getting total amount of collateral token available for withdrawal
    uint256 availableCollateralD18 = ICollateralModule(_asset).getAccountAvailableCollateral(
      params.accountId,
      params.collateralType
    );
    // Calculating total value of collateral token available for withdrawal using factory oracles for that collateral
    uint256 availableWithdrawValue = _assetValue(_pool, params.collateralType, availableCollateralD18);
    // Balance of investor's portion in Synthetix V3 position technically equals its value
    uint256 withdrawValue = balance.mul(_withdrawPortion).div(10 ** 18);

    // Guard to prevent division by zero and to check if there is enough available collateral to perform withdrawal
    require(availableWithdrawValue >= withdrawValue && availableWithdrawValue > 0, "not enough available balance");
    // Calculating how much collateral token should be withdrawn to get investor's portion
    uint256 withdrawAmountD18 = availableCollateralD18.mul(withdrawValue).div(availableWithdrawValue);
    // Amount passed further to the transaction must be denominated with asset's native decimal representation
    params.withdrawAmount = withdrawAmountD18.div(params.collateralType.getPrecisionForConversion());

    // Get stored market data for collateral type
    SynthetixV3Structs.AllowedMarket memory allowedMarket = ISynthetixV3SpotMarketContractGuard(
      IHasGuardInfo(IPoolLogic(_pool).factory()).getContractGuard(snxSpotMarket)
    ).allowedMarkets(params.collateralType);

    // Checking if unwrapping is required
    if (allowedMarket.marketId > 0 && allowedMarket.collateralAsset != address(0)) {
      // If market data for collateral type is stored, then unwrapping is required
      transactions = _prepareTransactions(params, allowedMarket);
    } else {
      // Otherwise get the transactions for withdrawing without unwrapping
      transactions = _prepareTransactions(params);
    }

    return (address(0), 0, transactions);
  }

  /// @notice Creates transactions for withdrawing when unwrapping IS required
  /// @param _params WithdrawTxsParams struct
  /// @param _allowedMarket AllowedMarket struct
  /// @return transactions Transactions to be executed
  function _prepareTransactions(
    WithdrawTxsParams memory _params,
    SynthetixV3Structs.AllowedMarket memory _allowedMarket
  ) internal view returns (MultiTransaction[] memory transactions) {
    transactions = new MultiTransaction[](3);

    // Withdrawing collateral token from Synthetix V3 position to the pool
    transactions[0].to = _params.snxV3Core;
    transactions[0].txData = abi.encodeWithSelector(
      ICollateralModule.withdraw.selector,
      _params.accountId,
      _params.collateralType,
      _params.withdrawAmount
    );

    // Converting amount to be received after unwrapping to match asset decimals
    uint256 minAmountReceived = _params.withdrawAmount.div(_allowedMarket.collateralAsset.getPrecisionForConversion());

    // Unwrapping collateral token
    transactions[1].to = snxSpotMarket;
    transactions[1].txData = abi.encodeWithSelector(
      IWrapperModule.unwrap.selector,
      _allowedMarket.marketId,
      _params.withdrawAmount,
      minAmountReceived
    );

    // Transferring unwrapped collateral token from the pool to the investor
    transactions[2].to = _allowedMarket.collateralAsset;
    transactions[2].txData = abi.encodeWithSelector(IERC20.transfer.selector, _params.to, minAmountReceived);
  }

  /// @notice Creates transactions for withdrawing when unwrapping IS NOT required
  /// @param _params WithdrawTxsParams struct
  /// @return transactions Transactions to be executed
  function _prepareTransactions(
    WithdrawTxsParams memory _params
  ) internal pure returns (MultiTransaction[] memory transactions) {
    transactions = new MultiTransaction[](2);

    // Withdrawing collateral token from Synthetix V3 position to the pool
    transactions[0].to = _params.snxV3Core;
    transactions[0].txData = abi.encodeWithSelector(
      ICollateralModule.withdraw.selector,
      _params.accountId,
      _params.collateralType,
      _params.withdrawAmount
    );

    // Transferring collateral token from the pool to the investor
    transactions[1].to = _params.collateralType;
    transactions[1].txData = abi.encodeWithSelector(IERC20.transfer.selector, _params.to, _params.withdrawAmount);
  }

  /// @dev Helper function to calculate value of the asset using factory oracles
  /// @dev Returns zero if the asset is not supported by the factory
  /// @param _pool Pool address (to get factory address)
  /// @param _asset Asset address
  /// @param _amountD18 Amount of the asset, denominated with 18 decimals of precision
  /// @return assetValue Value of the asset
  function _assetValue(address _pool, address _asset, uint256 _amountD18) internal view returns (uint256 assetValue) {
    if (IHasAssetInfo(IPoolLogic(_pool).factory()).isValidAsset(_asset)) {
      address poolManagerLogic = IPoolLogic(_pool).poolManagerLogic();
      // Pass the amount, denominated with asset's native decimal representation
      uint256 amountToPass = _amountD18.div(_asset.getPrecisionForConversion());
      assetValue = IPoolManagerLogic(poolManagerLogic).assetValue(_asset, amountToPass);
    } else {
      assetValue = 0;
    }
  }

  /// @dev Helper function to get Synthetix V3 position details
  /// @dev Uses Synthetix V3 contract guard to get the data not to store anything in asset guard
  /// @param _pool Pool address
  /// @param _synthetixV3Core Synthetix V3 core address
  /// @return accountId Synthetix V3 NFT token ID associated with the pool
  /// @return collateralType Collateral token address
  /// @return poolId Liquidity Pool ID from Synthetix V3 system
  /// @return debtAsset Debt token address in Synthetix V3 system
  function _getPoolPositionDetails(
    address _pool,
    address _synthetixV3Core
  ) internal view returns (uint128 accountId, address collateralType, uint128 poolId, address debtAsset) {
    ISynthetixV3ContractGuard contractGuard = ISynthetixV3ContractGuard(
      IHasGuardInfo(IPoolLogic(_pool).factory()).getContractGuard(_synthetixV3Core)
    );
    accountId = contractGuard.getAccountNftTokenId(_pool, _synthetixV3Core);
    SynthetixV3Structs.VaultSetting memory vaultSetting = contractGuard.dHedgeVaultsWhitelist(_pool);
    collateralType = vaultSetting.collateralAsset;
    poolId = vaultSetting.snxLiquidityPoolId;
    debtAsset = vaultSetting.debtAsset;
  }

  /// @dev Helper function to calculate balance of the Synthetix V3 position
  /// @param _pool Pool address
  /// @param _asset Asset address (Basically Synthetix V3 core address)
  /// @param _accountId Synthetix V3 NFT token ID associated with the pool
  /// @param _collateralType Collateral token address
  /// @param _debtAsset Debt token address
  /// @param _debtD18 Amount of position debt, denominated with 18 decimals of precision
  /// @return balance Balance of the Synthetix V3 position
  function _calculateBalance(
    address _pool,
    address _asset,
    uint128 _accountId,
    address _collateralType,
    address _debtAsset,
    int256 _debtD18
  ) internal view returns (uint256 balance) {
    // If there is no Synthetix V3 NFT stored in our system associated with the pool, then balance is zero
    if (_accountId == 0) {
      return 0;
    }

    // Getting value of collateral that can be withdrawn or delegated to pools (it's not affected by debt)
    balance = _assetValue(
      _pool,
      _collateralType,
      ICollateralModule(_asset).getAccountAvailableCollateral(_accountId, _collateralType)
    );
    // Adding value of collateral that is snxUSD tokens minted
    balance = balance.add(
      _assetValue(_pool, _debtAsset, ICollateralModule(_asset).getAccountAvailableCollateral(_accountId, _debtAsset))
    );
    // Getting amount of collateral that is delegated to pools (this collateral is affected by debt)
    (, uint256 totalAssignedD18, ) = ICollateralModule(_asset).getAccountCollateral(_accountId, _collateralType);
    uint256 assignedCollateralValue = _assetValue(_pool, _collateralType, totalAssignedD18);

    if (_debtD18 < 0) {
      // Negative debt means credit. With this in mind, we calculate debt value in USD and add it to assigned collateral value
      balance = balance.add(assignedCollateralValue.add(_assetValue(_pool, _debtAsset, (-_debtD18).toUint256())));
    } else {
      // When debt is zero or positive, we calculate position's USD balance by subtracting value of the debt from value of the collateral
      // Debt's value which is bigger than collateral value would mean that position can be liquidated
      // trySub will return 0 result in that case
      (, uint256 result) = assignedCollateralValue.trySub((_assetValue(_pool, _debtAsset, _debtD18.toUint256())));
      balance = balance.add(result);
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
pragma experimental ABIEncoderV2;

import "../IHasSupportedAsset.sol";

interface IAssetGuard {
  struct MultiTransaction {
    address to;
    bytes txData;
  }

  function withdrawProcessing(
    address pool,
    address asset,
    uint256 withdrawPortion,
    address to
  ) external returns (address, uint256, MultiTransaction[] memory transactions);

  function getBalance(address pool, address asset) external view returns (uint256 balance);

  function getDecimals(address asset) external view returns (uint256 decimals);

  function removeAssetCheck(address poolLogic, address asset) external view;
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

pragma solidity 0.7.6;

interface IMutableBalanceAssetGuard {
  function isStateMutatingGuard() external view returns (bool);

  function getBalanceMutable(address pool, address asset) external returns (uint256 balance);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Module for managing user collateral.
 * @notice Allows users to deposit and withdraw collateral from the system.
 */
interface ICollateralModule {
  /**
   * @notice Deposits `tokenAmount` of collateral of type `collateralType` into account `accountId`.
   * @dev Anyone can deposit into anyone's active account without restriction.
   * @param accountId The id of the account that is making the deposit.
   * @param collateralType The address of the token to be deposited.
   * @param tokenAmount The amount being deposited, denominated in the token's native decimal representation.
   *
   * Emits a {Deposited} event.
   */
  function deposit(uint128 accountId, address collateralType, uint256 tokenAmount) external;

  /**
   * @notice Withdraws `tokenAmount` of collateral of type `collateralType` from account `accountId`.
   * @param accountId The id of the account that is making the withdrawal.
   * @param collateralType The address of the token to be withdrawn.
   * @param tokenAmount The amount being withdrawn, denominated in the token's native decimal representation.
   *
   * Requirements:
   *
   * - `msg.sender` must be the owner of the account, have the `ADMIN` permission, or have the `WITHDRAW` permission.
   *
   * Emits a {Withdrawn} event.
   *
   */
  function withdraw(uint128 accountId, address collateralType, uint256 tokenAmount) external;

  /**
   * @notice Returns the total values pertaining to account `accountId` for `collateralType`.
   * @param accountId The id of the account whose collateral is being queried.
   * @param collateralType The address of the collateral type whose amount is being queried.
   * @return totalDeposited The total collateral deposited in the account, denominated with 18 decimals of precision.
   * @return totalAssigned The amount of collateral in the account that is delegated to pools, denominated with 18 decimals of precision.
   * @return totalLocked The amount of collateral in the account that cannot currently be undelegated from a pool, denominated with 18 decimals of precision.
   */
  function getAccountCollateral(
    uint128 accountId,
    address collateralType
  ) external view returns (uint256 totalDeposited, uint256 totalAssigned, uint256 totalLocked);

  /**
   * @notice Returns the amount of collateral of type `collateralType` deposited with account `accountId` that can be withdrawn or delegated to pools.
   * @param accountId The id of the account whose collateral is being queried.
   * @param collateralType The address of the collateral type whose amount is being queried.
   * @return amountD18 The amount of collateral that is available for withdrawal or delegation, denominated with 18 decimals of precision.
   */
  function getAccountAvailableCollateral(
    uint128 accountId,
    address collateralType
  ) external view returns (uint256 amountD18);

  /**
   * @notice Clean expired locks from locked collateral arrays for an account/collateral type. It includes offset and items to prevent gas exhaustion. If both, offset and items, are 0 it will traverse the whole array (unlimited).
   * @param accountId The id of the account whose locks are being cleared.
   * @param collateralType The address of the collateral type to clean locks for.
   * @param offset The index of the first lock to clear.
   * @param count The number of slots to check for cleaning locks. Set to 0 to clean all locks at/after offset
   * @return cleared the number of locks that were actually expired (and therefore cleared)
   */
  function cleanExpiredLocks(
    uint128 accountId,
    address collateralType,
    uint256 offset,
    uint256 count
  ) external returns (uint256 cleared);

  /**
   * @notice Create a new lock on the given account. you must have `admin` permission on the specified account to create a lock.
   * @dev Collateral can be withdrawn from the system if it is not assigned or delegated to a pool. Collateral locks are an additional restriction that applies on top of that. I.e. if collateral is not assigned to a pool, but has a lock, it cannot be withdrawn.
   * @dev Collateral locks are initially intended for the Synthetix v2 to v3 migration, but may be used in the future by the Spartan Council, for example, to create and hand off accounts whose withdrawals from the system are locked for a given amount of time.
   * @param accountId The id of the account for which a lock is to be created.
   * @param collateralType The address of the collateral type for which the lock will be created.
   * @param amount The amount of collateral tokens to wrap in the lock being created, denominated with 18 decimals of precision.
   * @param expireTimestamp The date in which the lock will become clearable.
   */
  function createLock(uint128 accountId, address collateralType, uint256 amount, uint64 expireTimestamp) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Module for liquidated positions and vaults that are below the liquidation ratio.
 */
interface ILiquidationModule {
  /**
   * @notice Emitted when an account is liquidated.
   * @param accountId The id of the account that was liquidated.
   * @param poolId The pool id of the position that was liquidated.
   * @param collateralType The collateral type used in the position that was liquidated.
   * @param liquidationData The amount of collateral liquidated, debt liquidated, and collateral awarded to the liquidator.
   * @param liquidateAsAccountId Account id that will receive the rewards from the liquidation.
   * @param sender The address of the account that is triggering the liquidation.
   */
  event Liquidation(
    uint128 indexed accountId,
    uint128 indexed poolId,
    address indexed collateralType,
    LiquidationData liquidationData,
    uint128 liquidateAsAccountId,
    address sender
  );

  /**
   * @notice Emitted when a vault is liquidated.
   * @param poolId The id of the pool whose vault was liquidated.
   * @param collateralType The collateral address of the vault that was liquidated.
   * @param liquidationData The amount of collateral liquidated, debt liquidated, and collateral awarded to the liquidator.
   * @param liquidateAsAccountId Account id that will receive the rewards from the liquidation.
   * @param sender The address of the account that is triggering the liquidation.
   */
  event VaultLiquidation(
    uint128 indexed poolId,
    address indexed collateralType,
    LiquidationData liquidationData,
    uint128 liquidateAsAccountId,
    address sender
  );

  /**
   * @notice Data structure that holds liquidation information, used in events and in return statements.
   */
  struct LiquidationData {
    uint256 debtLiquidated;
    uint256 collateralLiquidated;
    uint256 amountRewarded;
  }

  /**
   * @notice Liquidates a position by distributing its debt and collateral among other positions in its vault.
   * @param accountId The id of the account whose position is to be liquidated.
   * @param poolId The id of the pool which holds the position that is to be liquidated.
   * @param collateralType The address of the collateral being used in the position that is to be liquidated.
   * @param liquidateAsAccountId Account id that will receive the rewards from the liquidation.
   * @return liquidationData Information about the position that was liquidated.
   */
  function liquidate(
    uint128 accountId,
    uint128 poolId,
    address collateralType,
    uint128 liquidateAsAccountId
  ) external returns (LiquidationData memory liquidationData);

  /**
   * @notice Liquidates an entire vault.
   * @dev Can only be done if the vault itself is under collateralized.
   * @dev LiquidateAsAccountId determines which account to deposit the seized collateral into (this is necessary particularly if the collateral in the vault is vesting).
   * @dev Will only liquidate a portion of the debt for the vault if `maxUsd` is supplied.
   * @param poolId The id of the pool whose vault is being liquidated.
   * @param collateralType The address of the collateral whose vault is being liquidated.
   * @param maxUsd The maximum amount of USD that the liquidator is willing to provide for the liquidation, denominated with 18 decimals of precision.
   * @return liquidationData Information about the vault that was liquidated.
   */
  function liquidateVault(
    uint128 poolId,
    address collateralType,
    uint128 liquidateAsAccountId,
    uint256 maxUsd
  ) external returns (LiquidationData memory liquidationData);

  /**
   * @notice Determines whether a specified position is liquidatable.
   * @param accountId The id of the account whose position is being queried for liquidation.
   * @param poolId The id of the pool whose position is being queried for liquidation.
   * @param collateralType The address of the collateral backing up the position being queried for liquidation.
   * @return canLiquidate A boolean with the response to the query.
   */
  function isPositionLiquidatable(
    uint128 accountId,
    uint128 poolId,
    address collateralType
  ) external returns (bool canLiquidate);

  /**
   * @notice Determines whether a specified vault is liquidatable.
   * @param poolId The id of the pool that owns the vault that is being queried for liquidation.
   * @param collateralType The address of the collateral being held at the vault that is being queried for liquidation.
   * @return canVaultLiquidate A boolean with the response to the query.
   */
  function isVaultLiquidatable(uint128 poolId, address collateralType) external returns (bool canVaultLiquidate);
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

import "../../utils/synthetixV3/libraries/SynthetixV3Structs.sol";

interface ISynthetixV3SpotMarketContractGuard {
  function allowedMarkets(
    address _synthAddress
  ) external view returns (SynthetixV3Structs.AllowedMarket memory allowedMarket);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Allows accounts to delegate collateral to a pool.
 * @dev Delegation updates the account's position in the vault that corresponds to the associated pool and collateral type pair.
 * @dev A pool contains one vault for each collateral type it supports, and vaults are not shared between pools.
 */
interface IVaultModule {
  /**
   * @notice Updates an account's delegated collateral amount for the specified pool and collateral type pair.
   * @param accountId The id of the account associated with the position that will be updated.
   * @param poolId The id of the pool associated with the position.
   * @param collateralType The address of the collateral used in the position.
   * @param amount The new amount of collateral delegated in the position, denominated with 18 decimals of precision.
   * @param leverage The new leverage amount used in the position, denominated with 18 decimals of precision.
   *
   * Requirements:
   *
   * - `msg.sender` must be the owner of the account, have the `ADMIN` permission, or have the `DELEGATE` permission.
   * - If increasing the amount delegated, it must not exceed the available collateral (`getAccountAvailableCollateral`) associated with the account.
   * - If decreasing the amount delegated, the liquidity position must have a collateralization ratio greater than the target collateralization ratio for the corresponding collateral type.
   *
   * Emits a {DelegationUpdated} event.
   */
  function delegateCollateral(
    uint128 accountId,
    uint128 poolId,
    address collateralType,
    uint256 amount,
    uint256 leverage
  ) external;

  /**
   * @notice Returns the collateralization ratio of the specified liquidity position. If debt is negative, this function will return 0.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @dev The return value is a percentage with 18 decimals places.
   * @param accountId The id of the account whose collateralization ratio is being queried.
   * @param poolId The id of the pool in which the account's position is held.
   * @param collateralType The address of the collateral used in the queried position.
   * @return ratioD18 The collateralization ratio of the position (collateral / debt), denominated with 18 decimals of precision.
   */
  function getPositionCollateralRatio(
    uint128 accountId,
    uint128 poolId,
    address collateralType
  ) external returns (uint256 ratioD18);

  /**
   * @notice Returns the debt of the specified liquidity position. Credit is expressed as negative debt.
   * @dev This is not a view function, and actually updates the entire debt distribution chain.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @param accountId The id of the account being queried.
   * @param poolId The id of the pool in which the account's position is held.
   * @param collateralType The address of the collateral used in the queried position.
   * @return debtD18 The amount of debt held by the position, denominated with 18 decimals of precision.
   */
  function getPositionDebt(uint128 accountId, uint128 poolId, address collateralType) external returns (int256 debtD18);

  /**
   * @notice Returns the amount and value of the collateral associated with the specified liquidity position.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @dev collateralAmount is represented as an integer with 18 decimals.
   * @dev collateralValue is represented as an integer with the number of decimals specified by the collateralType.
   * @param accountId The id of the account being queried.
   * @param poolId The id of the pool in which the account's position is held.
   * @param collateralType The address of the collateral used in the queried position.
   * @return collateralAmountD18 The amount of collateral used in the position, denominated with 18 decimals of precision.
   * @return collateralValueD18 The value of collateral used in the position, denominated with 18 decimals of precision.
   */
  function getPositionCollateral(
    uint128 accountId,
    uint128 poolId,
    address collateralType
  ) external view returns (uint256 collateralAmountD18, uint256 collateralValueD18);

  /**
   * @notice Returns all information pertaining to a specified liquidity position in the vault module.
   * @param accountId The id of the account being queried.
   * @param poolId The id of the pool in which the account's position is held.
   * @param collateralType The address of the collateral used in the queried position.
   * @return collateralAmountD18 The amount of collateral used in the position, denominated with 18 decimals of precision.
   * @return collateralValueD18 The value of the collateral used in the position, denominated with 18 decimals of precision.
   * @return debtD18 The amount of debt held in the position, denominated with 18 decimals of precision.
   * @return collateralizationRatioD18 The collateralization ratio of the position (collateral / debt), denominated with 18 decimals of precision.
   **/
  function getPosition(
    uint128 accountId,
    uint128 poolId,
    address collateralType
  )
    external
    returns (
      uint256 collateralAmountD18,
      uint256 collateralValueD18,
      int256 debtD18,
      uint256 collateralizationRatioD18
    );

  /**
   * @notice Returns the total debt (or credit) that the vault is responsible for. Credit is expressed as negative debt.
   * @dev This is not a view function, and actually updates the entire debt distribution chain.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @param poolId The id of the pool that owns the vault whose debt is being queried.
   * @param collateralType The address of the collateral of the associated vault.
   * @return debtD18 The overall debt of the vault, denominated with 18 decimals of precision.
   **/
  function getVaultDebt(uint128 poolId, address collateralType) external returns (int256 debtD18);

  /**
   * @notice Returns the amount and value of the collateral held by the vault.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @dev collateralAmount is represented as an integer with 18 decimals.
   * @dev collateralValue is represented as an integer with the number of decimals specified by the collateralType.
   * @param poolId The id of the pool that owns the vault whose collateral is being queried.
   * @param collateralType The address of the collateral of the associated vault.
   * @return collateralAmountD18 The collateral amount of the vault, denominated with 18 decimals of precision.
   * @return collateralValueD18 The collateral value of the vault, denominated with 18 decimals of precision.
   */
  function getVaultCollateral(
    uint128 poolId,
    address collateralType
  ) external returns (uint256 collateralAmountD18, uint256 collateralValueD18);

  /**
   * @notice Returns the collateralization ratio of the vault. If debt is negative, this function will return 0.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @dev The return value is a percentage with 18 decimals places.
   * @param poolId The id of the pool that owns the vault whose collateralization ratio is being queried.
   * @param collateralType The address of the collateral of the associated vault.
   * @return ratioD18 The collateralization ratio of the vault, denominated with 18 decimals of precision.
   */
  function getVaultCollateralRatio(uint128 poolId, address collateralType) external returns (uint256 ratioD18);
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