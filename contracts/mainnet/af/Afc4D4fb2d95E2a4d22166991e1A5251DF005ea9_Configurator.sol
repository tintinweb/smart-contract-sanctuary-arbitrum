// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {IACLManager} from "../interfaces/IACLManager.sol";
import {ICore} from "../interfaces/ICore.sol";

/**
 * @title BaseAuthorized
 * @notice Authorizes AethirCore contract to perform actions
 */
abstract contract BaseAuthorized {
    IACLManager internal immutable _aclManager;

    modifier onlyCore() {
        _aclManager.requireCore(msg.sender);
        _;
    }

    modifier onlyOperator() {
        _aclManager.requireOperator(msg.sender);
        _;
    }

    modifier onlyMigrator() {
        _aclManager.requireMigrator(msg.sender);
        _;
    }

    modifier onlyRiskAdmin() {
        _aclManager.requireRiskAdmin(msg.sender);
        _;
    }

    constructor(IACLManager aclManager) {
        require(
            address(aclManager) != address(0),
            "ACL manager cannot be zero"
        );
        _aclManager = aclManager;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {BaseAuthorized} from "./BaseAuthorized.sol";
import {IACLManager} from "../interfaces/IACLManager.sol";
import {IConfigurator} from "../interfaces/IConfigurator.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract Configurator is IConfigurator, BaseAuthorized {
    uint256 private constant EPOCH_DURATION = 15 minutes;
    uint8 private constant KVALUE_DECIMALS = 5;
    uint256 private immutable _deployTs;
    uint256 private _yearlyEmission;
    uint256[] private _stakingCoefficient;
    mapping(uint16 => uint256[]) private _kValues;
    uint64 private _rewardLockedTime;
    uint64 private _vestingPeriod;
    uint256 private _wholesaleMaintenanceTime;
    mapping(uint16 => ServiceFee) private _serviceFees;
    uint256 private _qMin;
    uint256 private _qMax;
    uint256[] private _sqLevels;

    constructor(
        IACLManager aclManager,
        uint256 deployTs
    ) BaseAuthorized(aclManager) {
        _deployTs = deployTs;
        _yearlyEmission = 50_000_000e18;
        _stakingCoefficient.push(203e17);
        _kValues[1].push(100_000);
        _kValues[2].push(140_000);
        _kValues[3].push(60_000);
        _kValues[4].push(30_000);
        _rewardLockedTime = 180;
        _vestingPeriod = 180;
    }

    /// @inheritdoc IConfigurator
    function getDeployTs() public view override returns (uint256) {
        return _deployTs;
    }

    /// @inheritdoc IConfigurator
    function getEpochDuration() public pure override returns (uint256) {
        return EPOCH_DURATION;
    }

    /// @inheritdoc IConfigurator
    function getEpoch() public view override returns (uint256) {
        return (block.timestamp - _deployTs) / EPOCH_DURATION;
    }

    /// @inheritdoc IConfigurator
    function getYearlyEmission() public view override returns (uint256) {
        return _yearlyEmission;
    }

    /// @inheritdoc IConfigurator
    function setYearlyEmission(uint256 value) public override onlyOperator {
        _yearlyEmission = value;
    }

    /// @inheritdoc IConfigurator
    function getStakingCoefficient()
        public
        view
        override
        returns (uint256 value, uint16 cp)
    {
        cp = SafeCast.toUint16(_stakingCoefficient.length - 1);
        value = _stakingCoefficient[cp];
    }

    /// @inheritdoc IConfigurator
    function getStakingCoefficientAtCheckpoint(
        uint16 cp
    ) public view override returns (uint256 value) {
        require(_stakingCoefficient.length > cp, "Invalid checkpoint");
        return _stakingCoefficient[cp];
    }

    /// @inheritdoc IConfigurator
    function setStakingCoefficient(uint256 value) public override onlyOperator {
        _stakingCoefficient.push(value);
    }

    /// @inheritdoc IConfigurator
    function getContainerKValue(
        uint16 index
    ) public view override returns (uint256 value, uint16 cp) {
        require(_kValues[index].length > 0, "KValue unset");
        cp = SafeCast.toUint16(_kValues[index].length - 1);
        value = _kValues[index][cp];
    }

    /// @inheritdoc IConfigurator
    function getContainerKValueAtCheckpoint(
        uint16 index,
        uint16 cp
    ) public view override returns (uint256 value) {
        require(_kValues[index].length > cp, "Invalid checkpoint");
        return _kValues[index][cp];
    }

    /// @inheritdoc IConfigurator
    function setContainerKValue(
        uint16[] calldata indexes,
        uint256[] calldata values
    ) public override onlyOperator {
        require(indexes.length == values.length, "Length mismatch");
        uint256 length = indexes.length;
        for (uint16 i = 0; i < length; i++) {
            _kValues[indexes[i]].push(values[i]);
        }
    }

    /// @inheritdoc IConfigurator
    function getKValueDecimals() public pure override returns (uint8) {
        return KVALUE_DECIMALS;
    }

    /// @inheritdoc IConfigurator
    function getRewardLockedTime() public view override returns (uint64) {
        return _rewardLockedTime;
    }

    /// @inheritdoc IConfigurator
    function setRewardLockedTime(uint64 value) public override onlyOperator {
        _rewardLockedTime = value;
    }

    /// @inheritdoc IConfigurator
    function getVestingPeriod() public view override returns (uint64) {
        return _vestingPeriod;
    }

    /// @inheritdoc IConfigurator
    function setVestingPeriod(uint64 value) public override onlyOperator {
        _vestingPeriod = value;
    }

    /// @notice returns quality parameter (Q)
    function getQualityParameter()
        public
        view
        override
        returns (uint256 min, uint256 max)
    {
        min = _qMin;
        max = _qMax;
    }

    /// @notice configures quality parameter (Q)
    /// @param min: min Q value
    /// @param max: max Q value
    function setQualityParameter(
        uint256 min,
        uint256 max
    ) public override onlyOperator {
        require(min < max, "Invalid value");
        _qMin = min;
        _qMax = max;
    }

    /// @notice returns average quality parameter (SQ)
    function getAverageQualityParameter()
        public
        view
        override
        returns (uint256[] memory)
    {
        return _sqLevels;
    }

    /// @notice configures average quality parameter (SQ)
    /// @param values: new SQ values
    function setAverageQualityParameter(
        uint256[] calldata values
    ) public override onlyOperator {
        _sqLevels = values;
    }

    /// @inheritdoc IConfigurator
    function getServiceFees(
        uint16 index
    ) public view override returns (ServiceFee memory) {
        return _serviceFees[index];
    }

    /// @inheritdoc IConfigurator
    function setServiceFees(
        uint16[] calldata indexes,
        ServiceFee[] calldata values
    ) public override onlyOperator {
        require(indexes.length == values.length, "Length mismatch");
        uint256 length = indexes.length;
        for (uint16 i = 0; i < length; i++) {
            _serviceFees[indexes[i]] = values[i];
        }
    }

    /// @inheritdoc IConfigurator
    function getWholesaleMaintenanceTime()
        public
        view
        override
        returns (uint256)
    {
        return _wholesaleMaintenanceTime;
    }

    /// @inheritdoc IConfigurator
    function setWholesaleMaintenanceTime(
        uint256 value
    ) public override onlyOperator {
        _wholesaleMaintenanceTime = value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

/**
 * @title IACLManager
 * @notice Defines the basic interface for the ACL Manager
 */
interface IACLManager {
    /// @notice thrown when tx has not been completed because it lacks valid authentication credentials
    error Unauthorized(string message);

    /// @notice true if the address is Core Module, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Core Module, false otherwise
    function isCore(address account) external view returns (bool);

    /// @notice revert if the address is not Core Module
    /// @param account: the address to check
    function requireCore(address account) external view;

    /// @notice true if the address is Originator, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Originator, false otherwise
    function isOriginator(address account) external view returns (bool);

    /// @notice revert if the address is not Originator
    /// @param account: the address to check
    function requireOriginator(address account) external view;

    /// @notice true if the address is Operator, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Operator, false otherwise
    function isOperator(address account) external view returns (bool);

    /// @notice revert if the address is not Operator
    /// @param account: the address to check
    function requireOperator(address account) external view;

    /// @notice true if the address is Migrator, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Migrator, false otherwise
    function isMigrator(address account) external view returns (bool);

    /// @notice revert if the address is not Migrator
    /// @param account: the address to check
    function requireMigrator(address account) external view;

    /// @notice true if the address is Validator, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Validator, false otherwise
    function isValidator(address account) external view returns (bool);

    /// @notice revert if the address is not Validator
    /// @param account: the address to check
    function requireValidator(address account) external view;

    /// @notice true if the address is Approver, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Approver, false otherwise
    function isApprover(address account) external view returns (bool);

    /// @notice revert if the address is not Approver
    /// @param account: the address to check
    function requireApprover(address account) external view;

    /// @notice true if the address is EmergencyAdmin, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is EmergencyAdmin, false otherwise
    function isEmergencyAdmin(address account) external view returns (bool);

    /// @notice revert if the address is not EmergencyAdmin
    /// @param account: the address to check
    function requireEmergencyAdmin(address account) external view;

    /// @notice true if the address is RiskAdmin, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is RiskAdmin, false otherwise
    function isRiskAdmin(address account) external view returns (bool);

    /// @notice revert if the address is not RiskAdmin
    /// @param account: the address to check
    function requireRiskAdmin(address account) external view;

    /// @notice get number of required validator signatures for verifiable data
    function getRequiredValidatorSignatures() external view returns (uint8);

    /// @notice set number of required validator signatures for verifiable data
    function setRequiredValidatorSignatures(uint8 value) external;

    /// @notice get number of required approver signatures for verifiable data
    function getRequiredApproverSignatures() external view returns (uint8);

    /// @notice set number of required approver signatures for verifiable data
    function setRequiredApproverSignatures(uint8 value) external;

    function checkValidatorSignatures(
        bytes32 dataHash,
        bytes calldata signatures
    ) external view;

    function checkApproverSignatures(
        bytes32 dataHash,
        bytes calldata signatures
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

interface IConfigurator {
    /// @notice service fee data
    /// @param retailUpside: retail service fee upside
    /// @param retailDownside: retail service fee downside
    /// @param wholesaleUpside: wholesale service fee upside
    /// @param wholesaleDownside: wholesale service fee downside
    struct ServiceFee {
        uint256 retailUpside;
        uint256 retailDownside;
        uint256 wholesaleUpside;
        uint256 wholesaleDownside;
    }

    /// @notice thrown when value is not valid
    error InvalidValue(string message);

    /// @notice returns first epoch start time (in UNIX timestamp)
    function getDeployTs() external view returns (uint256);

    /// @notice returns epoch duration (in seconds)
    function getEpochDuration() external view returns (uint256);

    /// @notice returns current system epoch
    function getEpoch() external view returns (uint256);

    /// @notice returns token amount released yearly
    function getYearlyEmission() external view returns (uint256);

    /// @notice configures token amount released yearly
    /// @param value: the new token amount
    function setYearlyEmission(uint256 value) external;

    /// @notice returns staking coefficient
    function getStakingCoefficient()
        external
        view
        returns (uint256 value, uint16 cp);

    /// @notice returns staking coefficient at checkpoint `cp`
    function getStakingCoefficientAtCheckpoint(
        uint16 cp
    ) external view returns (uint256 value);

    /// @notice configures staking coefficient
    /// @param value: the new staking coefficient
    function setStakingCoefficient(uint256 value) external;

    /// @notice returns k-value for container ith configuration
    function getContainerKValue(
        uint16 index
    ) external view returns (uint256 value, uint16 cp);

    /// @notice returns k-value for container ith configuration at checkpoint `cp`
    function getContainerKValueAtCheckpoint(
        uint16 index,
        uint16 cp
    ) external view returns (uint256 value);

    /// @notice configures k-values for each container configuration
    /// @param indexes: the k-indexes
    /// @param values: the new k-values
    function setContainerKValue(
        uint16[] calldata indexes,
        uint256[] calldata values
    ) external;

    /// @notice returns the number of decimals used to get its user representation.
    /// For example, if `decimals` equals `2`, a kValue of `505` should
    /// be displayed to a user as `5.05` (`505 / 10 ** 2`)
    function getKValueDecimals() external view returns (uint8);

    /// @notice returns reward locked time before vesting
    function getRewardLockedTime() external view returns (uint64);

    /// @notice configures reward locked time before vesting
    /// @param value: new locked time (in days)
    function setRewardLockedTime(uint64 value) external;

    /// @notice returns vesting period
    function getVestingPeriod() external view returns (uint64);

    /// @notice configures vesting period
    /// @param value: new vesting period (in days)
    function setVestingPeriod(uint64 value) external;

    /// @notice returns quality parameter (Q)
    function getQualityParameter()
        external
        view
        returns (uint256 min, uint256 max);

    /// @notice configures quality parameter (Q)
    /// @param min: min Q value
    /// @param max: max Q value
    function setQualityParameter(uint256 min, uint256 max) external;

    /// @notice returns average quality parameter (SQ)
    function getAverageQualityParameter()
        external
        view
        returns (uint256[] memory);

    /// @notice configures average quality parameter (SQ)
    /// @param values: new SQ values
    function setAverageQualityParameter(uint256[] calldata values) external;

    /// @notice returns service fee for container ith configuration
    function getServiceFees(
        uint16 index
    ) external view returns (ServiceFee memory);

    /// @notice configures wholesale service fee for each container configuration
    /// @param indexes: the k-indexes
    /// @param values: the new service fee
    function setServiceFees(
        uint16[] calldata indexes,
        ServiceFee[] calldata values
    ) external;

    /// @notice returns wholesale maintenance time
    function getWholesaleMaintenanceTime() external view returns (uint256);

    /// @notice configures wholesale maintenance time
    /// @param value: new wholesale maintenance time
    function setWholesaleMaintenanceTime(uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

/**
 * @dev Interface of Aethir Core Contract
 */
interface ICore {
    /// @notice verifiable off-chain data
    /// @param nonce: off-chain request id
    /// @param deadline: deadline timestamp as seconds since Unix epoch
    /// @param lastUpdateBlock: last indexed event blocknumber
    /// @param version: system version
    /// @param payloads: data package (format according to system version)
    /// @param proof: data proof (Validator Signature or Merkle Proof)
    struct VerifiableData {
        uint64 nonce;
        uint64 deadline;
        uint64 lastUpdateBlock;
        uint64 version;
        bytes[] payloads;
        bytes[] proof;
    }

    /// @notice list of containers
    /// @param offset: index of the first container in the bitset, must be multiples of 256
    /// @param bitset: bit[n] = 1 mean enable container at index `offset`+`n`
    struct ContainerList {
        uint16 count;
        uint32 offset;
        bytes bitset;
    }

    /// @notice emitted after a successful stake containers request
    event Stake(
        address indexed provider,
        uint64 nonce,
        ContainerList containers
    );

    /// @notice emitted after a successful unstake containers request
    event Unstake(
        address indexed provider,
        uint64 nonce,
        ContainerList containers
    );

    /// @notice emitted after a successful claim reward request
    event ClaimReward(
        address indexed provider,
        uint64 nonce,
        ContainerList containers
    );

    /// @notice emitted after a successful claim service fee request
    event ClaimServiceFee(
        address indexed provider,
        uint64 nonce,
        ContainerList containers
    );

    /// @notice emitted after a successful deposit service fee request
    event DepositServiceFee(
        address indexed developer,
        uint64 nonce,
        uint256 amount
    );

    /// @notice emitted after a successful withdraw service fee request
    event WithdrawServiceFee(
        address indexed developer,
        uint64 nonce,
        uint256 amount
    );

    /// @notice emitted after system update version
    event VersionUpdate(uint64 indexed oldVersion, uint64 indexed newVersion);

    /// @notice emitted after a successful force unstake containers request
    event ForceUnstake(
        address indexed operator,
        uint64 nonce,
        address[] providers,
        uint32[] indexes
    );

    /// @notice thrown when data version does not match with system version
    error InvalidVersion();

    /// @notice thrown when data deadline exceeded block timestamp
    error DataExpired();

    /// @notice thrown when data nonce is lower than the last id
    error NonceTooLow();

    /// @notice thrown when data payload is invalid
    error InvalidPayload();

    /// @notice thrown when parameter is invalid
    error InvalidParameter(string message);

    /// @notice thrown when data merkle proof or signature is invalid
    error InvalidProof();

    /// @notice thrown when on-chain and off-chain data are out-of-sync
    error DataTooOld();

    /// @notice thrown when there is abnormal data
    error DataConflict(string message);

    /// @notice Returns the current system version
    function version() external view returns (uint64);

    /// @notice Returns the current system epoch
    function currentEpoch()
        external
        view
        returns (uint64 epoch, uint64 startTs, uint64 endTs);

    /// @notice Returns the current nonce for `owner`
    /// A higher nonce must be included whenever generate a signature
    /// Every successful call update `owner`'s nonce to the new one
    /// This prevents a signature from being used multiple times.
    function nonces(address owner) external view returns (uint64);

    /// @notice Container Provider stake multiple containers
    /// @dev Caller must have allowance for this contract of at least stake amount
    /// @param containers: list of containers to stake
    /// @param vdata: additional data for calculating stake amount
    function stakeContainers(
        ContainerList calldata containers,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Container Provider unstake and claim reward for multiple containers
    /// @param containers: list of containers to unstake
    /// @param vdata: additional data for calculating unstake amount, reward and service fee
    function unstakeContainers(
        ContainerList calldata containers,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Container Provider claim reward for multiple containers
    /// @dev Reward will be sent to Vesting Controller and released following schedule
    /// @param containers: list of container to claim reward
    /// @param vdata: additional data for calculating reward amount
    function claimReward(
        ContainerList calldata containers,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Container Provider claim service fee for multiple containers
    /// @param containers: list of container to claim service fee
    /// @param vdata: additional data for calculating service fee amount
    function claimServiceFee(
        ContainerList calldata containers,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Game Developer deposit service fee
    /// @dev Caller must have allowance for this contract of at least deposit amount
    /// @param amount: amount of token game developer want to deposit
    /// @param vdata: additional data for calculating depositable service fee
    function depositServiceFee(
        uint256 amount,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Game Developer withdraw service fee
    /// @param amount: amount of token game developer want to withdraw
    /// @param vdata: additional data for calculating withdrawable service fee
    function withdrawServiceFee(
        uint256 amount,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Operator force unstake multiple containers
    /// @param providers: address of providers
    /// @param indexes: unstaked container index
    /// @param vdata: additional data for calculating remain stake number
    function forceUnstake(
        address[] calldata providers,
        uint32[] calldata indexes,
        VerifiableData calldata vdata
    ) external returns (bool);
}