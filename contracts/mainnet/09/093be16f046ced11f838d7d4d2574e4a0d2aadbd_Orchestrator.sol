// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ======================== Orchestrator ========================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {IGMXDataStore} from "./interfaces/IGMXDataStore.sol";

import {IGMXV2OrchestratorReader} from "./utilities/interfaces/IGMXV2OrchestratorReader.sol";
import {IGMXV2OrchestratorSetter} from "./utilities/interfaces/IGMXV2OrchestratorSetter.sol";

import {BaseOrchestrator, Authority} from "../BaseOrchestrator.sol";

/// @title Orchestrator
/// @notice This contract extends the ```BaseOrchestrator``` and is modified to fit GMX V2 (GMX Synthtics)
contract Orchestrator is BaseOrchestrator {

    using SafeCast for int256;

    uint256 private constant _FLOAT_DECIMALS = 30;

    // ============================================================================================
    // Constructor
    // ============================================================================================

    /// @notice The ```constructor``` function is called on deployment
    /// @param _authority The Authority contract instance
    /// @param _reader The Reader contract address
    /// @param _setter The Setter contract address
    constructor(
        Authority _authority,
        address _reader,
        address _setter
    ) BaseOrchestrator(_authority, _reader, _setter) {}

    // ============================================================================================
    // View Functions
    // ============================================================================================

    function getPrice(address _token) override external view returns (uint256) {
        bytes32 _priceFeedKey = keccak256(abi.encode(keccak256(abi.encode("PRICE_FEED")), _token));
        address _priceFeedAddress = IGMXDataStore(IGMXV2OrchestratorReader(address(reader)).gmxDataStore()).getAddress(_priceFeedKey);
        if (_priceFeedAddress == address(0)) revert PriceFeedNotSet();

        IPriceFeed _priceFeed = IPriceFeed(_priceFeedAddress);

        (
            /* uint80 roundID */,
            int256 _price,
            /* uint256 startedAt */,
            uint256 _timestamp,
            /* uint80 answeredInRound */
        ) = _priceFeed.latestRoundData();

        if (_price <= 0) revert InvalidPrice();
        if (block.timestamp > _timestamp && block.timestamp - _timestamp > 24 hours) revert StalePrice();

        return _price.toUint256() * 10 ** (_FLOAT_DECIMALS - _priceFeed.decimals());
    }

    // ============================================================================================
    // Internal Functions
    // ============================================================================================

    function _initialize(bytes memory _data) internal override {
        IGMXV2OrchestratorSetter(address(setter)).storeGMXAddresses(_data);
    }

    // ============================================================================================
    // Errors
    // ============================================================================================

    error PriceFeedNotSet();
    error InvalidPrice();
    error StalePrice();
}

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title IPriceFeed
/// @dev Interface for a price feed
interface IPriceFeed {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IGMXDataStore {
    function getUint(bytes32 key) external view returns (uint256);
    function getAddress(bytes32 key) external view returns (address);
    function getBytes32Count(bytes32 key) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title IGMXV2OrchestratorReader
/// @dev Interface for GMXV2OrchestratorReader contract
interface IGMXV2OrchestratorReader {
    function gmxDataStore() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title IGMXV2OrchestratorSetter
/// @dev Interface for GMXV2OrchestratorSetter contract
interface IGMXV2OrchestratorSetter {
    function storeGMXAddresses(bytes memory _data) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ====================== BaseOrchestrator ======================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {Auth, Authority} from "@solmate/auth/Auth.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {OrchestratorHelper, Keys} from "./libraries/OrchestratorHelper.sol";

import {IWETH} from "../utilities/interfaces/IWETH.sol";
import {IBaseOrchestratorSetter} from "../utilities/interfaces/IBaseOrchestratorSetter.sol";
import {IBaseOrchestratorReader} from "../utilities/interfaces/IBaseOrchestratorReader.sol";

import {IBaseRouteFactory} from "./interfaces/IBaseRouteFactory.sol";
import {IBaseOrchestrator, IBaseRoute} from "./interfaces/IBaseOrchestrator.sol";

/// @title BaseOrchestrator
/// @notice This abstract contract contains the logic for managing Routes and Puppets
abstract contract BaseOrchestrator is IBaseOrchestrator, Auth, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant MAX_FEE = 1000; // 10% max fee

    bool private _initialized;

    IBaseOrchestratorReader public immutable reader;
    IBaseOrchestratorSetter public immutable setter;

    // ============================================================================================
    // Constructor
    // ============================================================================================

    /// @notice The ```constructor``` function is called on deployment
    /// @param _authority The Authority contract instance
    /// @param _reader The Reader contract address
    /// @param _setter The Setter contract address
    constructor(Authority _authority, address _reader, address _setter) Auth(address(0), _authority) {
        reader = IBaseOrchestratorReader(_reader);
        setter = IBaseOrchestratorSetter(_setter);
    }

    // ============================================================================================
    // Modifiers
    // ============================================================================================

    /// @notice Modifier that ensures the caller is a route
    modifier onlyRoute() {
        OrchestratorHelper.isRouteRegistered(reader, msg.sender);
        _;
    }

    /// @notice Modifier that ensures the contract is not paused
    modifier notPaused() {
        OrchestratorHelper.isPaused(reader);
        _;
    }

    // ============================================================================================
    // View Functions
    // ============================================================================================

    // global

    /// @inheritdoc IBaseOrchestrator
    function getPrice(address _token) virtual external view returns (uint256);

    // ============================================================================================
    // Trader Function
    // ============================================================================================

    /// @inheritdoc IBaseOrchestrator
    // slither-disable-next-line reentrancy-no-eth
    function registerRouteAccount(
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bytes memory _data
    ) public nonReentrant notPaused returns (bytes32) {
        (
            address _route,
            bytes32 _routeKey,
            bytes32 _routeTypeKey
        ) = OrchestratorHelper.registerRouteAccount(
            reader,
            setter,
            msg.sender,
            _collateralToken,
            _indexToken,
            _isLong,
            _data
        );

        emit RegisterRouteAccount(msg.sender, _route, _routeTypeKey);

        return _routeKey;
    }

    /// @inheritdoc IBaseOrchestrator
    function requestPosition(
        IBaseRoute.AdjustPositionParams memory _adjustPositionParams,
        IBaseRoute.SwapParams memory _swapParams,
        bytes32 _routeTypeKey,
        uint256 _executionFee,
        bool _isIncrease
    ) public payable nonReentrant notPaused returns (bytes32 _requestKey) {
        bytes32 _routeKey = reader.routeKey(msg.sender, _routeTypeKey);
        address _route = OrchestratorHelper.validateRouteKey(reader, _routeKey);

        OrchestratorHelper.removeExpiredSubscriptions(reader, setter, _routeKey);

        if (_isIncrease && (msg.value == _executionFee)) {
            address _token = _swapParams.path[0];
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _swapParams.amount);
        }

        _requestKey = IBaseRoute(_route).requestPosition{ value: msg.value }(
            _adjustPositionParams,
            _swapParams,
            _executionFee,
            _isIncrease
        );

        if (reader.isPositionOpen(_routeKey)) {
            emit AdjustPosition(msg.sender, _route, _isIncrease, _requestKey, _routeTypeKey, _getPositionKey(_route));
        } else {
            emit OpenPosition(
                reader.subscribedPuppets(_routeKey),
                msg.sender,
                _route,
                _isIncrease,
                _requestKey, 
                _routeTypeKey,
                _getPositionKey(_route)
            );
        }
    }

    /// @inheritdoc IBaseOrchestrator
    function registerRouteAccountAndRequestPosition(
        IBaseRoute.AdjustPositionParams memory _adjustPositionParams,
        IBaseRoute.SwapParams memory _swapParams,
        uint256 _executionFee,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bytes memory _data
    ) external payable returns (bytes32 _routeKey, bytes32 _requestKey) {
        _routeKey = registerRouteAccount(_collateralToken, _indexToken, _isLong, _data);

        _requestKey = requestPosition(
            _adjustPositionParams,
            _swapParams,
            Keys.routeTypeKey(_collateralToken, _indexToken, _isLong, _data),
            _executionFee,
            true
        );
    }

    // ============================================================================================
    // Puppet Functions
    // ============================================================================================

    /// @inheritdoc IBaseOrchestrator
    function subscribeRoute(
        uint256 _allowance,
        uint256 _expiry,
        address _puppet,
        address _trader,
        bytes32 _routeTypeKey, 
        bool _subscribe
    ) public nonReentrant notPaused {
        if (msg.sender != reader.multiSubscriber()) _puppet = msg.sender;

        address _route = OrchestratorHelper.subscribePuppet(
            reader,
            setter,
            _expiry,
            _allowance,
            _trader,
            _puppet,
            _routeTypeKey,
            _subscribe
        );

        emit SubscribeRoute(_allowance, _expiry, _trader, _puppet, _route, _routeTypeKey, _subscribe);
    }

    /// @inheritdoc IBaseOrchestrator
    function batchSubscribeRoute(
        address _owner,
        uint256[] memory _allowances,
        uint256[] memory _expiries,
        address[] memory _traders,
        bytes32[] memory _routeTypeKeys,
        bool[] memory _subscribe
    ) public {
        if (_traders.length != _allowances.length) revert MismatchedInputArrays();
        if (_traders.length != _expiries.length) revert MismatchedInputArrays();
        if (_traders.length != _subscribe.length) revert MismatchedInputArrays();
        if (_traders.length != _routeTypeKeys.length) revert MismatchedInputArrays();

        for (uint256 i = 0; i < _traders.length; i++) {
            subscribeRoute(_allowances[i], _expiries[i], _owner, _traders[i], _routeTypeKeys[i], _subscribe[i]);
        }
    }

    /// @inheritdoc IBaseOrchestrator
    function deposit(uint256 _amount, address _asset, address _puppet) public payable nonReentrant notPaused {
        OrchestratorHelper.validatePuppetInput(reader, _amount, _puppet, _asset);

        if (msg.value > 0) {
            if (_amount != msg.value) revert InvalidAmount();
            if (_asset != reader.wnt()) revert InvalidAsset();
        }

        _creditPuppetAccount(_amount, _asset, msg.sender);

        if (msg.value > 0) {
            payable(_asset).functionCallWithValue(abi.encodeWithSignature("deposit()"), _amount);
        } else {
            IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        }

        emit Deposit(_amount, _asset, msg.sender, _puppet);
    }

    /// @inheritdoc IBaseOrchestrator
    function depositAndBatchSubscribe(
        uint256 _amount,
        address _asset,
        address _owner,
        uint256[] memory _allowances,
        uint256[] memory _expiries,
        address[] memory _traders,
        bytes32[] memory _routeTypeKeys,
        bool[] memory _subscribe
    ) external payable {
        deposit(_amount, _asset, _owner);

        batchSubscribeRoute(_owner, _allowances, _expiries, _traders, _routeTypeKeys, _subscribe);
    }

    /// @inheritdoc IBaseOrchestrator
    function withdraw(uint256 _amount, address _asset, address _receiver, bool _isETH) external nonReentrant {
        OrchestratorHelper.validatePuppetInput(reader, _amount, _receiver, _asset);

        if (_isETH && _asset != reader.wnt()) revert InvalidAsset();
 
        _debitPuppetAccount(_amount, _asset, msg.sender, true);

        if (_isETH) {
            IWETH(_asset).withdraw(_amount);
            payable(_receiver).sendValue(_amount);
        } else {
            IERC20(_asset).safeTransfer(_receiver, _amount);
        }

        emit Withdraw(_amount, _asset, _receiver, msg.sender);
    }

    /// @inheritdoc IBaseOrchestrator
    function setThrottleLimit(uint256 _throttleLimit, bytes32 _routeType) external nonReentrant notPaused {
        setter.updateThrottleLimit(_throttleLimit, msg.sender, _routeType);

        emit SetThrottleLimit(msg.sender, _routeType, _throttleLimit);
    }

    // ============================================================================================
    // Route Functions
    // ============================================================================================

    /// @inheritdoc IBaseOrchestrator
    function debitPuppetAccount(uint256[] memory _amounts, address[] memory _puppets, address _asset) external onlyRoute {
        for (uint256 i = 0; i < _puppets.length; i++) {
            _debitPuppetAccount(_amounts[i], _asset, _puppets[i], false);
        }
    } 

    /// @inheritdoc IBaseOrchestrator
    function creditPuppetAccount(uint256[] memory _amounts, address[] memory _puppets, address _asset) external onlyRoute {
        for (uint256 i = 0; i < _puppets.length; i++) {
            _creditPuppetAccount(_amounts[i], _asset, _puppets[i]);
        }
    }

    /// @inheritdoc IBaseOrchestrator
    function updateLastPositionOpenedTimestamp(address[] memory _puppets) external onlyRoute {
        bytes32 _routeType = OrchestratorHelper.updateLastPositionOpenedTimestamp(
            reader,
            setter,
            msg.sender,
            _puppets
        );

        emit UpdateOpenTimestamp(_puppets, _routeType);
    }

    /// @inheritdoc IBaseOrchestrator
    function transferRouteFunds(uint256 _amount, address _asset, address _receiver) external onlyRoute {
        IERC20(_asset).safeTransfer(_receiver, _amount);

        emit TransferRouteFunds(_amount, _asset, _receiver, msg.sender);
    }

    /// @inheritdoc IBaseOrchestrator
    function emitExecutionCallback(uint256 _performanceFeePaid, bytes32 _requestKey, bool _isExecuted, bool _isIncrease) external onlyRoute {
        emit ExecutePosition(_performanceFeePaid, msg.sender, _requestKey, _isExecuted, _isIncrease);
    }

    /// @inheritdoc IBaseOrchestrator
    function emitSharesIncrease(uint256[] memory _puppetsShares, uint256 _traderShares, uint256 _totalSupply) external onlyRoute {
        emit SharesIncrease(_puppetsShares, _traderShares, _totalSupply, _getPositionKey(msg.sender));
    }

    // ============================================================================================
    // Authority Functions
    // ============================================================================================

    // called by keeper

    /// @inheritdoc IBaseOrchestrator
    function adjustTargetLeverage(
        IBaseRoute.AdjustPositionParams memory _adjustPositionParams,
        uint256 _executionFee,
        bytes32 _routeKey
    ) external payable requiresAuth nonReentrant returns (bytes32 _requestKey) {
        address _route = OrchestratorHelper.validateRouteKey(reader, _routeKey);

        _requestKey = IBaseRoute(_route).decreaseSize{ value: msg.value }(_adjustPositionParams, _executionFee);

        emit AdjustTargetLeverage(_route, _requestKey, _routeKey, _getPositionKey(_route));
    }

    /// @inheritdoc IBaseOrchestrator
    function liquidatePosition(bytes32 _routeKey) external requiresAuth nonReentrant {
        address _route = OrchestratorHelper.validateRouteKey(reader, _routeKey);

        IBaseRoute(_route).liquidate();

        emit LiquidatePosition(_route, _routeKey, _getPositionKey(_route));
    }

    // called by owner

    /// @inheritdoc IBaseOrchestrator
    function initialize(
        address _keeper,
        address _platformFeeRecipient,
        address _routeFactory,
        address _routeSetter,
        address _gauge,
        bytes memory _data
    ) external requiresAuth {
        if (_initialized) revert AlreadyInitialized();
        if (_keeper == address(0)) revert ZeroAddress();
        if (_platformFeeRecipient == address(0)) revert ZeroAddress();
        if (_routeFactory == address(0)) revert ZeroAddress();
        if (_routeSetter == address(0)) revert ZeroAddress();

        _initialized = true;

        setter.setInitializeData(
            _keeper,
            _platformFeeRecipient,
            _routeFactory,
            _gauge,
            address(this),
            _routeSetter
        );

        _initialize(_data);

        emit Initialize(_keeper, _platformFeeRecipient, _routeFactory, _gauge, _routeSetter);
    }

    /// @inheritdoc IBaseOrchestrator
    function withdrawPlatformFees(address _asset) external returns (uint256 _balance) {
        if (_asset == address(0)) revert ZeroAddress();

        _balance = reader.platformAccountBalance(_asset);
        if (_balance == 0) revert ZeroAmount();

        setter.updatePlatformAccountBalance(0, _asset);

        address _platformFeeRecipient = reader.platformFeeRecipient();
        IERC20(_asset).safeTransfer(_platformFeeRecipient, _balance);

        emit WithdrawPlatformFees(_balance, _asset, msg.sender, _platformFeeRecipient);
    }

    /// @inheritdoc IBaseOrchestrator
    function updateRouteFactory(address _routeFactory) external requiresAuth {
        if (_routeFactory == address(0)) revert ZeroAddress();

        setter.updateRouteFactory(_routeFactory);

        emit UpdateRouteFactory(_routeFactory);
    }

    /// @inheritdoc IBaseOrchestrator
    function updateMultiSubscriber(address _multiSubscriber) external requiresAuth {
        if (_multiSubscriber == address(0)) revert ZeroAddress();

        setter.updateMultiSubscriber(_multiSubscriber);

        emit UpdateMultiSubscriber(_multiSubscriber);
    }

    /// @inheritdoc IBaseOrchestrator
    function setRouteType(address _collateralToken, address _indexToken, bool _isLong, bytes memory _data) external requiresAuth {
        bytes32 _routeTypeKey = Keys.routeTypeKey(_collateralToken, _indexToken, _isLong, _data);
        setter.setRouteType(_routeTypeKey, _collateralToken, _indexToken, _isLong);

        emit SetRouteType(_routeTypeKey, _collateralToken, _indexToken, _isLong);
    }

    /// @inheritdoc IBaseOrchestrator
    function updateKeeper(address _keeper) external requiresAuth {
        if (_keeper == address(0)) revert ZeroAddress();

        setter.updateKeeper(_keeper);

        emit UpdateKeeper(_keeper);
    }

    /// @inheritdoc IBaseOrchestrator
    function updateScoreGauge(address _gauge) external requiresAuth {
        if (_gauge == address(0)) revert ZeroAddress();

        setter.updateScoreGauge(_gauge);

        emit UpdateScoreGauge(_gauge);
    }

    /// @inheritdoc IBaseOrchestrator
    function updateReferralCode(bytes32 _referralCode) external requiresAuth {
        if (_referralCode == bytes32(0)) revert ZeroBytes32();

        setter.updateReferralCode(_referralCode);

        emit UpdateReferralCode(_referralCode);
    }

    /// @inheritdoc IBaseOrchestrator
    function updatePlatformFeesRecipient(address _recipient) external requiresAuth {
        if (_recipient == address(0)) revert ZeroAddress();

        setter.updatePlatformFeesRecipient(_recipient);

        emit SetFeesRecipient(_recipient);
    }

    /// @inheritdoc IBaseOrchestrator
    function updatePauseSwitch(bool _paused) external requiresAuth {
        setter.updatePauseSwitch(_paused);

        emit Pause(_paused);
    }

    /// @inheritdoc IBaseOrchestrator
    function setFees(uint256 _managmentFee, uint256 _withdrawalFee, uint256 _performanceFee) external requiresAuth nonReentrant {
        if (_managmentFee > MAX_FEE || _withdrawalFee > MAX_FEE || _performanceFee > MAX_FEE) revert FeeExceedsMax();

        setter.updateFees(_managmentFee, _withdrawalFee, _performanceFee);

        emit SetFees(_managmentFee, _withdrawalFee, _performanceFee);
    }

    /// @inheritdoc IBaseOrchestrator
    function rescueRouteFunds(uint256 _amount, address _token, address _receiver, address _route) external requiresAuth nonReentrant {
        IBaseRoute(_route).rescueTokenFunds(_amount, _token, _receiver);

        emit RescueRouteFunds(_amount, _token, _receiver, _route);
    }

    // ============================================================================================
    // Internal Mutated Functions
    // ============================================================================================

    function _initialize(bytes memory _data) internal virtual {}

    function _debitPuppetAccount(uint256 _amount, address _asset, address _puppet, bool _isWithdraw) internal {
        uint256 _feeAmount = (
            _isWithdraw
            ? (_amount * reader.withdrawalFeePercentage())
            : (_amount * reader.managementFeePercentage())
        ) / reader.basisPointsDivisor();

        setter.debitPuppetAccount(_amount, _feeAmount, _asset, _puppet);

        emit DebitPuppet(_amount, _asset, _puppet, msg.sender);
        emit CreditPlatform(_feeAmount, _asset, _puppet, msg.sender, _isWithdraw);
    }

    function _creditPuppetAccount(uint256 _amount, address _asset, address _puppet) internal {
        setter.creditPuppetAccount(_amount, _asset, _puppet);

        emit CreditPuppet(_amount, _asset, _puppet, msg.sender);
    }

    // ============================================================================================
    // Internal View Functions
    // ============================================================================================

    function _getPositionKey(address _route) internal view returns (bytes32) {
        return reader.positionKey(_route);
    }

    // ============================================================================================
    // Receive Function
    // ============================================================================================

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnershipTransferred(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function transferOwnership(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

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

    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Keys} from "../../utilities/libraries/Keys.sol";

import {IBaseOrchestratorReader} from "../../utilities/interfaces/IBaseOrchestratorReader.sol";
import {IBaseOrchestratorSetter} from "../../utilities/interfaces/IBaseOrchestratorSetter.sol";

import {IBaseRouteFactory} from "../interfaces/IBaseRouteFactory.sol";

library OrchestratorHelper {

    // ============================================================================================
    // View Functions
    // ============================================================================================

    function isRouteRegistered(IBaseOrchestratorReader _reader, address _route) external view {
        if (!_reader.isRouteRegistered(_route)) revert NotRoute();
    }

    function isPaused(IBaseOrchestratorReader _reader) external view {
        if (_reader.isPaused()) revert Paused();
    }

    function validateRouteKey(IBaseOrchestratorReader _reader, bytes32 _routeKey) public view returns (address _route) {
        _route = _reader.routeAddress(_routeKey);
        if (_route == address(0)) revert RouteNotRegistered();
    }

    function validatePuppetInput(
        IBaseOrchestratorReader _reader,
        uint256 _amount,
        address _puppet,
        address _asset
    ) external view {
        if (_amount == 0) revert ZeroAmount();
        if (_puppet == address(0)) revert ZeroAddress();
        if (_asset == address(0)) revert ZeroAddress();
        if (!_reader.isCollateralToken(_asset)) revert NotCollateralToken();
    }

    // ============================================================================================
    // Mutated Function
    // ============================================================================================

    function registerRouteAccount(
        IBaseOrchestratorReader _reader,
        IBaseOrchestratorSetter _setter,
        address _trader,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bytes memory _data
    ) external returns (address _route, bytes32 _routeKey, bytes32 _routeTypeKey) {
        if (_collateralToken == address(0) || _indexToken == address(0)) revert ZeroAddress();

        _routeTypeKey = Keys.routeTypeKey(_collateralToken, _indexToken, _isLong, _data);
        if (!_reader.isRouteTypeRegistered(_routeTypeKey)) revert RouteTypeNotRegistered();

        _routeKey = _reader.routeKey(_trader, _routeTypeKey);
        if (_reader.isRouteRegistered(_routeKey)) revert RouteAlreadyRegistered();

        _route = IBaseRouteFactory(_reader.routeFactory()).registerRouteAccount(
            _reader.routeReader(),
            _reader.routeSetter(),
            _data
        );

        _setter.setNewAccount(
            _route,
            _trader,
            _collateralToken,
            _indexToken,
            _isLong,
            _routeKey,
            _routeTypeKey
        );
    }

    function removeExpiredSubscriptions(
        IBaseOrchestratorReader _reader,
        IBaseOrchestratorSetter _setter,
        bytes32 _routeKey
    ) external {
        uint256 i = 0;
        while (i < _reader.subscribedPuppetsCount(_routeKey)) {
            address _puppet = _reader.puppetAt(_routeKey, i);
            if (_reader.puppetSubscriptionExpiry(_puppet, _routeKey) <= block.timestamp) {
                _setter.removeRouteSubscription(_puppet, _routeKey);
            } else {
                i++;
            }
        }
    }

    function subscribePuppet(
        IBaseOrchestratorReader _reader,
        IBaseOrchestratorSetter _setter,
        uint256 _expiry,
        uint256 _allowance,
        address _trader,
        address _puppet,
        bytes32 _routeTypeKey,
        bool _subscribe
    ) external returns (address _route) {
        bytes32 _routeKey = _reader.routeKey(_trader, _routeTypeKey);
        _route = validateRouteKey(_reader, _routeKey);
        if (_reader.isWaitingForCallback(_routeKey)) revert RouteWaitingForCallback();

        _setter.updateSubscription(_expiry, _allowance, _puppet, _subscribe, _routeKey);
    }

    function updateLastPositionOpenedTimestamp(
        IBaseOrchestratorReader _reader,
        IBaseOrchestratorSetter _setter,
        address _route,
        address[] memory _puppets
    ) external returns (bytes32 _routeType) {
        _routeType = _reader.routeType(_route);
        for (uint256 i = 0; i < _puppets.length; i++) {
            _setter.updateLastPositionOpenedTimestamp(_puppets[i], _routeType);
        }
    }

    // ============================================================================================
    // Errors
    // ============================================================================================

    error NotRoute();
    error Paused();
    error ZeroAddress();
    error ZeroAmount();
    error RouteTypeNotRegistered();
    error RouteAlreadyRegistered();
    error RouteNotRegistered();
    error RouteWaitingForCallback();
    error NotCollateralToken();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IWETH {
    
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ================= BaseOrchestratorSetter =====================
// ==============================================================

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

/// @title IBaseOrchestratorSetter
/// @dev Interface for BaseOrchestratorSetter contract
interface IBaseOrchestratorSetter {

    function setOwner(address _owner) external;
    function setInitializeData(address _keeper, address _platformFeesRecipient, address _routeFactory, address _gauge, address _orchestrator, address _routeSetter) external;
    function setNewAccount(address _route, address _trader, address _collateralToken, address _indexToken, bool _isLong, bytes32 _routeKey, bytes32 _routeTypeKey) external;
    function setRouteType(bytes32 _routeTypeKey, address _collateralToken, address _indexToken, bool _isLong) external;
    function updateSubscription(uint256 _expiry, uint256 _allowance, address _puppet, bool _subscribe, bytes32 _routeKey) external;
    function updateThrottleLimit(uint256 _throttleLimit, address _puppet, bytes32 _routeType) external;
    function updateLastPositionOpenedTimestamp(address _puppet, bytes32 _routeType) external;
    function updatePlatformAccountBalance(uint256 _balance, address _asset) external;
    function updateFees(uint256 _managementFee, uint256 _withdrawalFee, uint256 _performanceFee) external;
    function updateRouteFactory(address _routeFactory) external;
    function updateMultiSubscriber(address _multiSubscriber) external;
    function updateKeeper(address _keeper) external;
    function updateScoreGauge(address _gauge) external;
    function updateReferralCode(bytes32 _referralCode) external;
    function updatePlatformFeesRecipient(address _recipient) external;
    function updatePauseSwitch(bool _paused) external;
    function removeRouteSubscription(address _puppet, bytes32 _routeKey) external;
    function debitPuppetAccount(uint256 _amount, uint256 _feeAmount, address _asset, address _puppet) external;
    function creditPuppetAccount(uint256 _amount, address _asset, address _puppet) external;

    // ============================================================================================
    // Errors
    // ============================================================================================

    error InvalidAllowancePercentage();
    error InvalidSubscriptionExpiry();
    error ZeroAddress();
    error Unauthorized();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ================ IBaseOrchestratorReader =====================
// ==============================================================

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {IBaseReader} from "./IBaseReader.sol";

/// @title IBaseOrchestratorReader
/// @dev Interface for BaseOrchestratorReader contract
interface IBaseOrchestratorReader is IBaseReader {

    // global

    function routeReader() external view returns (address);
    function routeSetter() external view returns (address);
    function platformAccountBalance(address _asset) external view returns (uint256);
    function isRouteTypeRegistered(bytes32 _routeTypeKey) external view returns (bool);

    // deployed contracts

    function routeFactory() external view returns (address);
    function multiSubscriber() external view returns (address);

    // keys

    function positionKey(address _route) external view returns (bytes32);

    // route

    function isWaitingForCallback(bytes32 _routeKey) external view returns (bool);
    function subscribedPuppetsCount(bytes32 _routeKey) external view returns (uint256);
    function puppetAt(bytes32 _routeKey, uint256 _index) external view returns (address);

    // puppets

    function puppetSubscriptions(address _puppet) external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ======================== IRouteFactory =======================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

interface IBaseRouteFactory {

    // ============================================================================================
    // External Functions
    // ============================================================================================

    /// @notice The ```registerRouteAccount``` is called on Orchestrator.registerRouteAccount
    /// @param _reader The address of the Reader
    /// @param _setter The Setter contract address
    /// @param _data The data to be passed to the Route
    /// @return _route The address of the new Route
    function registerRouteAccount(address _reader, address _setter, bytes memory _data) external returns (address _route);

    // ============================================================================================
    // Events
    // ============================================================================================

    event RegisterRouteAccount(address indexed caller, address route, address reader, address setter, bytes data);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ====================== IBaseOrchestrator =====================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {IBaseRoute} from "./IBaseRoute.sol";

interface IBaseOrchestrator {

    // ============================================================================================
    // View Functions
    // ============================================================================================

    // global

    /// @notice The ```getPrice``` function returns the price for a given Token from the GMX vaultPriceFeed
    /// @notice prices are USD denominated with 30 decimals
    /// @param _token The address of the Token
    /// @return _price The price
    function getPrice(address _token) external view returns (uint256 _price);

    // ============================================================================================
    // Mutated Functions
    // ============================================================================================

    // Trader

    /// @notice The ```registerRouteAccount``` function is called by a Trader to register a new Route Account
    /// @param _collateralToken The address of the Collateral Token
    /// @param _indexToken The address of the Index Token
    /// @param _isLong The boolean value of the position
    /// @param _data Any additional data
    /// @return bytes32 The Route key
    function registerRouteAccount(address _collateralToken, address _indexToken, bool _isLong, bytes memory _data) external returns (bytes32);

    /// @notice The ```requestPosition``` function creates a new position request
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _swapParams The swap data of the Trader, enables the Trader to add collateral with a non-collateral token
    /// @param _routeTypeKey The RouteType key
    /// @param _executionFee The total execution fee, paid by the Trader in ETH
    /// @param _isIncrease The boolean indicating if the request is an increase or decrease request
    /// @return _requestKey The request key
    function requestPosition(IBaseRoute.AdjustPositionParams memory _adjustPositionParams, IBaseRoute.SwapParams memory _swapParams, bytes32 _routeTypeKey, uint256 _executionFee, bool _isIncrease) external payable returns (bytes32 _requestKey);

    /// @notice The ```registerRouteAccountAndRequestPosition``` function is called by a Trader to register a new Route Account and create an Increase Position Request
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _swapParams The swap data of the Trader, enables the Trader to add collateral with a non-collateral token
    /// @param _executionFee The total execution fee, paid by the Trader in ETH
    /// @param _collateralToken The address of the Collateral Token
    /// @param _indexToken The address of the Index Token
    /// @param _isLong The boolean value of the position
    /// @param _data Any additional data
    /// @return _routeKey The Route key
    /// @return _requestKey The request key
    function registerRouteAccountAndRequestPosition(IBaseRoute.AdjustPositionParams memory _adjustPositionParams, IBaseRoute.SwapParams memory _swapParams, uint256 _executionFee, address _collateralToken, address _indexToken, bool _isLong, bytes memory _data) external payable returns (bytes32 _routeKey, bytes32 _requestKey);

    // Puppet

    /// @notice The ```subscribeRoute``` function is called by a Puppet to update his subscription to a Route
    /// @param _allowance The allowance percentage
    /// @param _subscriptionPeriod The subscription period
    /// @param _puppet The subscribing Puppet
    /// @param _trader The address of the Trader
    /// @param _routeTypeKey The RouteType key
    /// @param _subscribe Whether to subscribe or unsubscribe
    function subscribeRoute(uint256 _allowance, uint256 _subscriptionPeriod, address _puppet, address _trader, bytes32 _routeTypeKey, bool _subscribe) external;

    /// @notice The ```batchSubscribeRoute``` function is called by a Puppet to update his subscription to a list of Routes
    /// @param _owner The subscribing Puppet
    /// @param _allowances The allowance percentage array
    /// @param _subscriptionPeriods The subscription period array
    /// @param _traders The address array of Traders
    /// @param _routeTypeKeys The RouteType key array
    /// @param _subscribe Whether to subscribe or unsubscribe
    function batchSubscribeRoute(address _owner, uint256[] memory _allowances, uint256[] memory _subscriptionPeriods, address[] memory _traders, bytes32[] memory _routeTypeKeys, bool[] memory _subscribe) external;

    /// @notice The ```deposit``` function is called by a Puppet to deposit funds into his deposit account
    /// @param _amount The amount to deposit
    /// @param _asset The address of the Asset
    /// @param _puppet The address of the recepient
    function deposit(uint256 _amount, address _asset, address _puppet) external payable;

    /// @notice The ```depositAndBatchSubscribe``` function is called by a Puppet to deposit funds into his deposit account and update his subscription to a list of Routes
    /// @param _amount The amount to deposit
    /// @param _asset The address of the Asset
    /// @param _owner The subscribing Puppet
    /// @param _allowances The allowance percentage array
    /// @param _expiries The subscription period array
    /// @param _traders The address array of Traders
    /// @param _routeTypeKeys The RouteType key array
    /// @param _subscribe Whether to subscribe or unsubscribe
    function depositAndBatchSubscribe(uint256 _amount, address _asset, address _owner, uint256[] memory _allowances, uint256[] memory _expiries, address[] memory _traders, bytes32[] memory _routeTypeKeys, bool[] memory _subscribe) external payable;

    /// @notice The ```withdraw``` function is called by a Puppet to withdraw funds from his deposit account
    /// @param _amount The amount to withdraw
    /// @param _asset The address of the Asset
    /// @param _receiver The address of the receiver of withdrawn funds
    /// @param _isETH Whether to withdraw ETH or not. Available only for WETH deposits
    function withdraw(uint256 _amount, address _asset, address _receiver, bool _isETH) external;

    /// @notice The ```setThrottleLimit``` function is called by a Puppet to set his throttle limit for a given RouteType
    /// @param _throttleLimit The throttle limit
    /// @param _routeType The RouteType key
    function setThrottleLimit(uint256 _throttleLimit, bytes32 _routeType) external;

    // Route

    /// @notice The ```debitPuppetAccount``` function is called by a Route to debit a Puppet's account
    /// @param _amounts The uint256 array of amounts to debit
    /// @param _puppets The address array of the Puppets to debit
    /// @param _asset The address of the Asset
    function debitPuppetAccount(uint256[] memory _amounts, address[] memory _puppets, address _asset) external;

    /// @notice The ```creditPuppetAccount``` function is called by a Route to credit a Puppet's account
    /// @param _amounts The uint256 array of amounts to credit
    /// @param _puppets The address array of the Puppets to credit
    /// @param _asset The address of the Asset
    function creditPuppetAccount(uint256[] memory _amounts, address[] memory _puppets, address _asset) external;

    /// @notice The ```updateLastPositionOpenedTimestamp``` function is called by a Route to update the last position opened timestamp of a Puppet
    /// @param _puppets The address array of the Puppets
    function updateLastPositionOpenedTimestamp(address[] memory _puppets) external;

    /// @notice The ```transferRouteFunds``` function is called by a Route to send funds to a _receiver
    /// @param _amount The amount to send
    /// @param _asset The address of the Asset
    /// @param _receiver The address of the receiver
    function transferRouteFunds(uint256 _amount, address _asset, address _receiver) external;

    /// @notice The ```emitExecutionCallback``` function is called by a Route to emit an event on a GMX position execution callback
    /// @param performanceFeePaid The performance fee paid to Trader
    /// @param _requestKey The request key
    /// @param _isExecuted The boolean indicating if the request is executed
    /// @param _isIncrease The boolean indicating if the request is an increase or decrease request
    function emitExecutionCallback(uint256 performanceFeePaid, bytes32 _requestKey, bool _isExecuted, bool _isIncrease) external;

    /// @notice The ```emitSharesIncrease``` function is called by a Route to emit an event on a successful add collateral request
    /// @param _puppetsShares The array of Puppets shares, corresponding to the Route's subscribed Puppets, as stored in the Route Position struct
    /// @param _traderShares The Trader's shares, as stored in the Route Position struct
    /// @param _totalSupply The total supply of the Route's shares
    function emitSharesIncrease(uint256[] memory _puppetsShares, uint256 _traderShares, uint256 _totalSupply) external;

    // Authority

    // called by keeper

    /// @notice The ```adjustTargetLeverage``` function is called by a keeper to adjust mirrored position to target leverage to match trader leverage
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _executionFee The total execution fee, paid by the Keeper in ETH
    /// @param _routeKey The Route key
    /// @return _requestKey The request key
    function adjustTargetLeverage(IBaseRoute.AdjustPositionParams memory _adjustPositionParams, uint256 _executionFee, bytes32 _routeKey) external payable returns (bytes32 _requestKey);

    /// @notice The ```liquidatePosition``` function is called by Puppet keepers to reset the Route's accounting in case of a liquidation
    /// @param _routeKey The Route key
    function liquidatePosition(bytes32 _routeKey) external;

    // called by owner

    /// @notice The ```initialize``` function is called by the Authority to initialize the contract
    /// @dev Function is callable only once and execution is paused until then
    /// @param _keeper The address of the Keeper
    /// @param _platformFeeRecipient The address of the platform fees recipient
    /// @param _routeFactory The address of the RouteFactory
    /// @param _routeSetter The address of the RouteSetter
    /// @param _gauge The address of the Score Gauge
    /// @param _data The bytes of any additional data
    function initialize(address _keeper, address _platformFeeRecipient, address _routeFactory, address _routeSetter, address _gauge, bytes memory _data) external;

    /// @notice The ```withdrawPlatformFees``` function is called by anyone to withdraw platform fees
    /// @param _asset The address of the Asset
    /// @return _amount The amount withdrawn
    function withdrawPlatformFees(address _asset) external returns (uint256 _amount);

    /// @notice The ```updateRouteFactory``` function is called by the Authority to set the RouteFactory address
    /// @param _routeFactory The address of the new RouteFactory
    function updateRouteFactory(address _routeFactory) external;

    /// @notice The ```updateMultiSubscriber``` function is called by the Authority to set the MultiSubscriber address
    /// @param _multiSubscriber The address of the new MultiSubscriber
    function updateMultiSubscriber(address _multiSubscriber) external;

    /// @notice The ```setRouteType``` function is called by the Authority to set a new RouteType
    /// @dev system doesn't support tokens that apply a fee/burn/rebase on transfer 
    /// @param _collateral The address of the Collateral Token
    /// @param _index The address of the Index Token
    /// @param _isLong The boolean value of the position
    /// @param _data Any additional data
    function setRouteType(address _collateral, address _index, bool _isLong, bytes memory _data) external;

    /// @notice The ```updateKeeper``` function is called by the Authority to set the Keeper address
    /// @param _keeperAddr The address of the new Keeper
    function updateKeeper(address _keeperAddr) external;

    /// @notice The ```updateScoreGauge``` function is called by the Authority to set the Score Gauge address
    /// @param _gauge The address of the new Score Gauge
    function updateScoreGauge(address _gauge) external;

    /// @notice The ```updateReferralCode``` function is called by the Authority to set the referral code
    /// @param _refCode The new referral code
    function updateReferralCode(bytes32 _refCode) external;

    /// @notice The ```updatePlatformFeesRecipient``` function is called by the Authority to set the platform fees recipient
    /// @param _recipient The new platform fees recipient
    function updatePlatformFeesRecipient(address _recipient) external;

    /// @notice The ```setPause``` function is called by the Authority to pause all Routes
    /// @param _pause The new pause state
    function updatePauseSwitch(bool _pause) external;

    /// @notice The ```setFees``` function is called by the Authority to set the management and withdrawal fees
    /// @param _managmentFee The new management fee
    /// @param _withdrawalFee The new withdrawal fee
    /// @param _performanceFee The new performance fee
    function setFees(uint256 _managmentFee, uint256 _withdrawalFee, uint256 _performanceFee) external;

    /// @notice The ```rescueRouteFunds``` function is called by the Authority to rescue tokens from a Route
    /// @dev Route should never hold any funds, but this function is here just in case
    /// @param _amount The amount to rescue
    /// @param _token The address of the Token
    /// @param _receiver The address of the receiver
    /// @param _route The address of the Route
    function rescueRouteFunds(uint256 _amount, address _token, address _receiver, address _route) external;

    // ============================================================================================
    // Events
    // ============================================================================================

    event RegisterRouteAccount(address indexed trader, address indexed route, bytes32 routeTypeKey);

    event SubscribeRoute(uint256 allowance, uint256 subscriptionExpiry, address indexed trader, address indexed puppet, address indexed route, bytes32 routeTypeKey, bool subscribe);
    event SetThrottleLimit(address indexed puppet, bytes32 routeType, uint256 throttleLimit);

    event UpdateOpenTimestamp(address[] indexed puppets, bytes32 routeType);
    
    event Deposit(uint256 amount, address asset, address caller, address indexed puppet);
    event Withdraw(uint256 amount, address asset, address indexed receiver, address indexed puppet);

    event AdjustPosition(address indexed trader, address indexed route, bool isIncrease, bytes32 requestKey, bytes32 routeTypeKey, bytes32 positionKey); 
    event OpenPosition(address[] puppets, address indexed trader, address indexed route, bool isIncrease, bytes32 requestKey, bytes32 routeTypeKey, bytes32 positionKey);
    event ExecutePosition(uint256 performanceFeePaid, address indexed route, bytes32 requestKey, bool isExecuted, bool isIncrease);
    event SharesIncrease(uint256[] puppetsShares, uint256 traderShares, uint256 totalSupply, bytes32 positionKey);
    event AdjustTargetLeverage(address indexed route, bytes32 requestKey, bytes32 routeKey, bytes32 positionKey);
    event LiquidatePosition(address indexed route, bytes32 routeKey, bytes32 positionKey);

    event DebitPuppet(uint256 amount, address asset, address indexed puppet, address indexed caller);
    event CreditPlatform(uint256 amount, address asset, address puppet, address caller, bool isWithdraw);
    event CreditPuppet(uint256 amount, address asset, address indexed puppet, address indexed caller);

    event TransferRouteFunds(uint256 amount, address asset, address indexed receiver, address indexed caller);
    event Initialize(address keeper, address platformFeeRecipient, address routeFactory, address gauge, address routeSetter);
    event WithdrawPlatformFees(uint256 amount, address asset, address caller, address platformFeeRecipient);

    event UpdateRouteFactory(address routeFactory);
    event UpdateMultiSubscriber(address multiSubscriber);
    event SetRouteType(bytes32 routeTypeKey, address collateral, address index, bool isLong);
    event UpdateKeeper(address keeper);
    event UpdateScoreGauge(address scoreGauge);
    event UpdateReferralCode(bytes32 referralCode);
    event SetFeesRecipient(address recipient);
    event Pause(bool paused);
    event SetFees(uint256 managmentFee, uint256 withdrawalFee, uint256 performanceFee);
    event RescueRouteFunds(uint256 amount, address token, address indexed receiver, address indexed route);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error MismatchedInputArrays();
    error RouteNotRegistered();
    error InvalidAmount();
    error InvalidAsset();
    error ZeroAddress();
    error ZeroBytes32();
    error ZeroAmount();
    error FunctionCallPastDeadline();
    error NotWhitelisted();
    error FeeExceedsMax();
    error AlreadyInitialized();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
    ) external;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title Keys
/// @dev Keys for values in the DataStore
library Keys {

    // DataStore.uintValues

    /// @dev key for management fee (DataStore.uintValues)
    bytes32 public constant MANAGEMENT_FEE = keccak256(abi.encode("MANAGEMENT_FEE"));
    /// @dev key for withdrawal fee (DataStore.uintValues)
    bytes32 public constant WITHDRAWAL_FEE = keccak256(abi.encode("WITHDRAWAL_FEE"));
    /// @dev key for performance fee (DataStore.uintValues)
    bytes32 public constant PERFORMANCE_FEE = keccak256(abi.encode("PERFORMANCE_FEE"));

    // DataStore.intValues

    // DataStore.addressValues

    /// @dev key for sending received fees
    bytes32 public constant PLATFORM_FEES_RECIPIENT = keccak256(abi.encode("PLATFORM_FEES_RECIPIENT"));
    /// @dev key for subscribing to multiple Routes
    bytes32 public constant MULTI_SUBSCRIBER = keccak256(abi.encode("MULTI_SUBSCRIBER"));
    /// @dev key for the address of the keeper
    bytes32 public constant KEEPER = keccak256(abi.encode("KEEPER"));
    /// @dev key for the address of the Score Gauge
    bytes32 public constant SCORE_GAUGE = keccak256(abi.encode("SCORE_GAUGE"));
    /// @dev key for the address of the Route Factory
    bytes32 public constant ROUTE_FACTORY = keccak256(abi.encode("ROUTE_FACTORY"));
    /// @dev key for the address of the Route Setter
    bytes32 public constant ROUTE_SETTER = keccak256(abi.encode("ROUTE_SETTER"));
    /// @dev key for the address of the Orchestrator
    bytes32 public constant ORCHESTRATOR = keccak256(abi.encode("ORCHESTRATOR"));

    // DataStore.boolValues

    /// @dev key for pause status
    bytes32 public constant PAUSED = keccak256(abi.encode("PAUSED"));

    // DataStore.stringValues

    // DataStore.bytes32Values

    /// @dev key for the referral code
    bytes32 public constant REFERRAL_CODE = keccak256(abi.encode("REFERRAL_CODE"));

    // DataStore.addressArrayValues

    /// @dev key for the array of routes
    bytes32 public constant ROUTES = keccak256(abi.encode("ROUTES"));


    // -------------------------------------------------------------------------------------------

    // global

    function routeTypeKey(address _collateralToken, address _indexToken, bool _isLong, bytes memory _data) public pure returns (bytes32) {
        return keccak256(abi.encode(_collateralToken, _indexToken, _isLong, _data));
    }

    function routeTypeCollateralTokenKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("COLLATERAL_TOKEN", _routeTypeKey));
    }

    function routeTypeIndexTokenKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("INDEX_TOKEN", _routeTypeKey));
    }

    function routeTypeIsLongKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_LONG", _routeTypeKey));
    }

    function routeTypeDataKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("DATA", _routeTypeKey));
    }

    function platformAccountKey(address _asset) public pure returns (bytes32) {
        return keccak256(abi.encode("PLATFORM_ACCOUNT", _asset));
    }

    function isRouteTypeRegisteredKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_ROUTE_TYPE_REGISTERED", _routeTypeKey));
    }

    function isCollateralTokenKey(address _token) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_COLLATERAL_TOKEN", _token));
    }

    function collateralTokenDecimalsKey(address _collateralToken) public pure returns (bytes32) {
        return keccak256(abi.encode("COLLATERAL_TOKEN_DECIMALS", _collateralToken));
    }

    // route

    function routeCollateralTokenKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_COLLATERAL_TOKEN", _route));
    }

    function routeIndexTokenKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_INDEX_TOKEN", _route));
    }

    function routeIsLongKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_IS_LONG", _route));
    }

    function routeTraderKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_TRADER", _route));
    }

    function routeDataKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_DATA", _route));
    }

    function routeRouteTypeKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_ROUTE_TYPE", _route));
    }

    function routeAddressKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_ADDRESS", _routeKey));
    }

    function routePuppetsKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_PUPPETS", _routeKey));
    }

    function targetLeverageKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("TARGET_LEVERAGE", _routeKey));
    }

    function isKeeperRequestsKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("KEEPER_REQUESTS", _routeKey, _requestKey));
    }

    function isRouteRegisteredKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_ROUTE_REGISTERED", _routeKey));
    }

    function isWaitingForKeeperAdjustmentKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_WAITING_FOR_KEEPER_ADJUSTMENT", _routeKey));
    }

    function isKeeperAdjustmentEnabledKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_KEEPER_ADJUSTMENT_ENABLED", _routeKey));
    }

    function isPositionOpenKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_POSITION_OPEN", _routeKey));
    }

    // route position

    function positionIndexKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_INDEX", _routeKey));
    }

    function positionPuppetsKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_PUPPETS", _positionIndex, _routeKey));
    }

    function positionTraderSharesKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TRADER_SHARES", _positionIndex, _routeKey));
    }

    function positionPuppetsSharesKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_PUPPETS_SHARES", _positionIndex, _routeKey));
    }

    function positionLastTraderAmountInKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_LAST_TRADER_AMOUNT_IN", _positionIndex, _routeKey));
    }

    function positionLastPuppetsAmountsInKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_LAST_PUPPETS_AMOUNTS_IN", _positionIndex, _routeKey));
    }

    function positionTotalSupplyKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TOTAL_SUPPLY", _positionIndex, _routeKey));
    }

    function positionTotalAssetsKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TOTAL_ASSETS", _positionIndex, _routeKey));
    }

    function cumulativeVolumeGeneratedKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("CUMULATIVE_VOLUME_GENERATED", _routeKey));
    }

    function puppetsPnLKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPETS_PNL", _routeKey));
    }

    function traderPnLKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("TRADER_PNL", _routeKey));
    }

    // route request

    function requestKeyToAddCollateralRequestsIndexKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("REQUEST_KEY_TO_ADD_COLLATERAL_REQUESTS_INDEX", _routeKey, _requestKey));
    }

    function addCollateralRequestsIndexKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUESTS_INDEX", _positionIndex, _routeKey));
    }

    function addCollateralRequestPuppetsSharesKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_SHARES", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestPuppetsAmountsKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_AMOUNTS", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTraderAmountInKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TRADER_AMOUNT_IN", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestPuppetsAmountInKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_AMOUNT_IN", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestIsAdjustmentRequiredKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_IS_ADJUSTMENT_REQUIRED", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTraderSharesKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TRADER_SHARES", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTotalSupplyKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TOTAL_SUPPLY", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTotalAssetsKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TOTAL_ASSETS", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function pendingSizeDeltaKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PENDING_SIZE_DELTA", _routeKey, _requestKey));
    }

    function requestKeysKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("REQUEST_KEYS", _positionIndex, _routeKey));
    }

    // puppet

    function puppetAllowancesKey(address _puppet) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_ALLOWANCES", _puppet));
    }

    function puppetSubscriptionExpiryKey(address _puppet, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_SUBSCRIPTION_EXPIRY", _puppet, _routeKey));
    }

    function puppetDepositAccountKey(address _puppet, address _asset) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_DEPOSIT_ACCOUNT", _puppet, _asset));
    }

    function puppetThrottleLimitKey(address _puppet, bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_THROTTLE_LIMIT", _puppet, _routeTypeKey));
    }

    function puppetLastPositionOpenedTimestampKey(address _puppet, bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_LAST_POSITION_OPENED_TIMESTAMP", _puppet, _routeTypeKey));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ====================== IBaseReader ===========================
// ==============================================================

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

/// @title IBaseReader
/// @dev Interface for BaseReader contract
interface IBaseReader {

    // global

    function precision() external pure returns (uint256);
    function withdrawalFeePercentage() external view returns (uint256);
    function managementFeePercentage() external view returns (uint256);
    function basisPointsDivisor() external pure returns (uint256);
    function collateralTokenDecimals(address _token) external view returns (uint256);
    function platformFeeRecipient() external view returns (address);
    function wnt() external view returns (address);
    function keeper() external view returns (address);
    function isPaused() external view returns (bool);
    function isCollateralToken(address _token) external view returns (bool);
    function isRouteRegistered(address _route) external view returns (bool);
    function isRouteRegistered(bytes32 _routeKey) external view returns (bool);
    function referralCode() external view returns (bytes32);
    function routes() external view returns (address[] memory);

    // keys
 
    function routeKey(address _route) external view returns (bytes32);
    function routeKey(address _trader, bytes32 _routeTypeKey) external view returns (bytes32);

    // deployed contracts

    function orchestrator() external view returns (address);
    function scoreGauge() external view returns (address);

    // puppets

    function puppetSubscriptionExpiry(address _puppet, bytes32 _routeKey) external view returns (uint256);
    function subscribedPuppets(bytes32 _routeKey) external view returns (address[] memory);

    // Route data

    function collateralToken(address _route) external view returns (address);
    function indexToken(address _route) external view returns (address);
    function trader(address _route) external view returns (address);
    function routeAddress(bytes32 _routeKey) external view returns (address);
    function routeAddress(address _trader, address _collateralToken, address _indexToken, bool _isLong, bytes memory _data) external view returns (address);
    function isLong(address _route) external view returns (bool);
    function isPositionOpen(bytes32 _routeKey) external view returns (bool);
    function routeType(address _route) external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ========================= IBaseRoute =========================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

interface IBaseRoute {

    struct AdjustPositionParams {
        uint256 collateralDelta;
        uint256 sizeDelta;
        uint256 acceptablePrice;
    }

    struct SwapParams {
        address[] path;
        uint256 amount;
        uint256 minOut;
    }

    // ============================================================================================
    // Mutated Functions
    // ============================================================================================

    // orchestrator

    // called by trader

    /// @notice The ```requestPosition``` function creates a new position request
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _swapParams The swap data of the Trader, enables the Trader to add collateral with a non-collateral token
    /// @param _executionFee The total execution fee, paid by the Trader in ETH
    /// @param _isIncrease The boolean indicating if the request is an increase or decrease request
    /// @return _requestKey The request key
    function requestPosition(AdjustPositionParams memory _adjustPositionParams, SwapParams memory _swapParams, uint256 _executionFee, bool _isIncrease) external payable returns (bytes32 _requestKey);

    // called by keeper

    /// @notice The ```decreaseSize``` function is called by Puppet keepers to decrease the position size in case there are Puppets to adjust
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _executionFee The total execution fee, paid by the Keeper in ETH
    /// @return _requestKey The request key
    function decreaseSize(AdjustPositionParams memory _adjustPositionParams, uint256 _executionFee) external payable returns (bytes32 _requestKey);

    /// @notice The ```liquidate``` function is called by Puppet keepers to reset the Route's accounting in case of a liquidation
    function liquidate() external;

    // called by owner

    /// @notice The ```rescueTokens``` is called by the Orchestrator and Authority to rescue tokens
    /// @param _amount The amount to rescue
    /// @param _token The token address
    /// @param _receiver The receiver address
    function rescueTokenFunds(uint256 _amount, address _token, address _receiver) external;

    // ============================================================================================
    // Events
    // ============================================================================================

    event Liquidate();
    event Callback(bytes32 requestKey, bool isExecuted, bool isIncrease);
    event IncreaseRequest(bytes32 requestKey, uint256 amountIn, uint256 sizeDelta, uint256 acceptablePrice);
    event DecreaseRequest(bytes32 requestKey, uint256 collateralDelta, uint256 sizeDelta, uint256 acceptablePrice);
    event Repay(uint256 totalAssets, uint256 performanceFeePaid);
    event RescueTokenFunds(uint256 amount, address token, address receiver);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error WaitingForKeeperAdjustment();
    error NotKeeper();
    error NotTrader();
    error InvalidExecutionFee();
    error PositionStillAlive();
    error PositionNotOpen();
    error Paused();
    error NotOrchestrator();
    error RouteFrozen();
    error NotCallbackCaller();
    error NotWaitingForKeeperAdjustment();
    error ZeroAddress();
    error KeeperAdjustmentDisabled();
}