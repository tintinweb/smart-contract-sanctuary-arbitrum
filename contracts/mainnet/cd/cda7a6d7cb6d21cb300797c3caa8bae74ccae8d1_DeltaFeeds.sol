// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

import "./interfaces/public/ICoreMultidataFeedsReader.sol";
import "./AbstractFeedsWithMetrics.sol";
import "./NonProxiedOwnerMultipartyCommons.sol";


/**
 * @notice Write-efficient oracle
 */
contract DeltaFeeds is ICoreMultidataFeedsReader, NonProxiedOwnerMultipartyCommons, AbstractFeedsWithMetrics {
    using ABDKMath64x64 for int128;

    /**
     * @notice Contract version, using SemVer version scheme.
     *
     * 0.2 - pre-multiparty branch
     * 0.3 - multiparty branch
     */
    string public constant override VERSION = "0.3.1";

    // Signed 64.64 fixed point number 1.002 gives us minimal distinguishable price change of 0.2%.
    int128 public constant DELTA_BASE = int128(uint128(1002 * 2 ** 64) / uint128(1000));

    // min delta is DELTA_BASE ** -512, max delta is DELTA_BASE ** 511
    uint256 public constant DELTA_BITS = 10;

    // keccak256("DeltaFeeds.deltas")
    uint256 private constant DELTAS_LOCATION = 0xe2fa74590d73fe2f2afa21f2ddf03c378ff30b2f89c8b95dfd3c290bdb4e0222;

    uint256 private constant NO_DELTA = 0;
    uint256 private constant DELTA_MODULO = 1 << DELTA_BITS;        // module for two's complement arithmetic
    uint256 private constant DELTA_MASK = DELTA_MODULO - 1;         // mask to extract a delta
    uint256 private constant DELTAS_PER_SLOT = 256 / DELTA_BITS;    // note that there may be unused bits in a slot
    uint256 private constant SLOT_PADDING_BITS = 256 - DELTAS_PER_SLOT * DELTA_BITS;    // unused bits in a slot

    int128 private constant ABDK_ONE = int128(int256(1 << 64));

    bytes32 immutable private UPDATE_TYPE_HASH;

    struct Status {
        // TODO add per-metric update timestamps
        uint32 epochId; // last unix timestamp of ANY update
    }

    Status internal status;

    uint[] internal prices;

    constructor() NonProxiedOwnerMultipartyCommons(address(this), block.chainid) {
        UPDATE_TYPE_HASH = keccak256("Update(uint32 epochId,uint32 previousEpochId,uint256[] metricIds,uint256[] basePrices,bytes deltas)");
    }

    /// @dev Status field getter.
    function getStatus() external view returns (Status memory) {
        return status;
    }

    // Exports state for updater (only!)
    function getState() external view returns (
        int128 DELTA_BASE_, uint256 DELTA_BITS_,
        uint32 epochId_,
        Metric[] memory metrics_, uint[] memory basePrices_, uint[] memory currentDeltas_
    ) {
        DELTA_BASE_ = DELTA_BASE;
        DELTA_BITS_ = DELTA_BITS;

        epochId_ = status.epochId;

        metrics_ = getMetrics();
        basePrices_ = prices;
        currentDeltas_ = new uint[](metrics_.length);
        // TODO optimize excess sload-s
        for (uint i = 0; i < currentDeltas_.length; i++)
            currentDeltas_[i] = getDelta(i);
    }


    /// @inheritdoc ICoreMultidataFeedsReader
    function quoteMetrics(string[] calldata names_) external view override returns (Quote[] memory quotes) {
        uint32 updateTS = status.epochId;
        uint256 length = names_.length;
        quotes = new Quote[](length);
        for (uint i = 0; i < length; i++) {
            (bool exists, uint id) = hasMetric(names_[i]);
            require(exists, "MultidataFeeds: METRIC_NOT_FOUND");

            // TODO optimize excess sload-s
            quotes[i] = Quote(getPrice(id), updateTS);
        }
    }

    /// @inheritdoc ICoreMultidataFeedsReader
    function quoteMetrics(uint256[] calldata ids) external view override returns (Quote[] memory quotes) {
        uint32 updateTS = status.epochId;
        uint256 length = ids.length;
        uint256 totalMetrics = getMetricsCount();
        quotes = new Quote[](length);
        for (uint i = 0; i < length; i++) {
            uint256 id = ids[i];
            require(id < totalMetrics, "MultidataFeeds: METRIC_NOT_FOUND");

            // TODO optimize excess sload-s
            quotes[i] = Quote(getPrice(id), updateTS);
        }
    }

    /// @notice Adds new metrics along with their current prices.
    /// @dev Internal implementation (it's marked external, but see selfCall)
    function addMetrics(Metric[] calldata metrics_, uint256[] calldata prices_, uint salt, uint deadline)
        external
        selfCall
        applicable(salt, deadline)
    {
        require(metrics_.length != 0 && metrics_.length == prices_.length, "MultidataFeeds: BAD_LENGTH");

        uint256 length = metrics_.length;
        for (uint256 i = 0; i < length; i++) {
            addMetric(metrics_[i]);
            prices.push(prices_[i]);
            require(getMetricsCount() == prices.length, 'MultidataFeeds: BROKEN_LOGIC');

            // no need - as we're hitting these bytes of storage for the first time - they're zeroed
            // setDelta(id, NO_DELTA);
        }
    }

    /// @notice Updates info of metrics_.
    function updateMetrics(Metric[] calldata metrics_, uint salt, uint deadline)
        external
        selfCall
        applicable(salt, deadline)
    {
        for (uint256 i = 0; i < metrics_.length; i++) {
            updateMetric(metrics_[i]);
        }
    }

    function update(uint32 epochId_, uint32 previousEpochId_, uint[] calldata metricIds_, uint256[] calldata prices_,
                    bytes calldata deltas_, uint8 v, bytes32 r, bytes32 s)
        external
    {
        checkUpdateAccess(epochId_, previousEpochId_, metricIds_, prices_, deltas_, v, r, s);

        require(epochId_ > previousEpochId_ && epochId_ <= block.timestamp, "MultidataFeeds: BAD_EPOCH");
        require(status.epochId == previousEpochId_, "MultidataFeeds: STALE_UPDATE");
        require(metricIds_.length == prices_.length, "MultidataFeeds: BAD_LENGTH");

        status.epochId = epochId_;
        bool hasDeltaUpdate = deltas_.length != 0;

        uint256 metricsCount = getMetricsCount();
        require(0 != metricsCount, "MultidataFeeds: NO_METRICS");

        if (metricIds_.length != 0) {
            // Base prices update (aka setPrice(s))
            uint256 length = metricIds_.length;
            for (uint256 i = 0; i < length; i++) {
                uint256 id = metricIds_[i];
                uint256 price = prices_[i];
                require(id < metricsCount, "MultidataFeeds: METRIC_NOT_FOUND");

                prices[id] = price;
                if (!hasDeltaUpdate)
                    setDelta(id, NO_DELTA);
            }
        }

        if (!hasDeltaUpdate) {
            emit MetricUpdated(epochId_, type(uint256).max-1);
            return;
        }

        // Updating deltas
        // deltas := [slot], [slot ...]
        // slot := delta, [delta ...], zero padding up to 256 bits
        // delta := signed DELTA_BITS-bit number, to be used as an exponent of DELTA_BASE
        uint256 slots = (metricsCount - 1) / DELTAS_PER_SLOT + 1;
        require(deltas_.length == 32 * slots, "MultidataFeeds: WRONG_LENGTH");

        // deltas offset is stored at the calldata offset:
        //      selector + uint(epochId_) + uint(previousEpochId_) + uint(metricIds_ offset) + uint(prices_ offset)
        //      == 4 + 4 * 32 == 132
        // plus, skipping the length word and selector (it's not a part of abi-coded offset)
        uint256 srcOffset;
        assembly {
            srcOffset := add(calldataload(132), 36)
        }
        // dstSlot - storage pointer
        for (uint256 dstSlot = DELTAS_LOCATION; dstSlot < DELTAS_LOCATION + slots; dstSlot++) {
            assembly {
                sstore(dstSlot, calldataload(srcOffset))
            }
            srcOffset += 32;
        }
        emit MetricUpdated(epochId_, type(uint256).max-1);
    }


    /// @dev Gets raw metric delta (signed logarithm encoded as two's complement)
    function getDelta(uint256 id) internal view returns (uint256) {
        uint256 slot = DELTAS_LOCATION + id / DELTAS_PER_SLOT;
        uint256 deltaBlock;
        assembly {
            deltaBlock := sload(slot)
        }

        // Unpack one delta from the slot contents
        return (deltaBlock >> getBitsAfterDelta(id)) & DELTA_MASK;
    }

    /// @dev Sets raw metric delta (signed logarithm encoded as two's complement)
    function setDelta(uint256 id, uint256 delta) internal {
        uint256 dstSlot = DELTAS_LOCATION + id / DELTAS_PER_SLOT;
        uint256 current;
        assembly {
            current := sload(dstSlot)
        }

        // Clear the delta & overwrite it with new content keeping others intact
        uint256 bitsAfterDelta = getBitsAfterDelta(id);
        current &= ~(DELTA_MASK << bitsAfterDelta);     // setting zeroes
        current |= delta << bitsAfterDelta;       // writing delta

        assembly {
            sstore(dstSlot, current)
        }
    }

    function getBitsAfterDelta(uint256 id) internal pure returns (uint256) {
        uint256 deltaIdx = id % DELTAS_PER_SLOT;
        return (DELTAS_PER_SLOT - 1 - deltaIdx) * DELTA_BITS + SLOT_PADDING_BITS;
    }

    function getPrice(uint256 id) internal view returns (uint256) {
        uint256 rawDelta = getDelta(id);
        int128 delta;
        if (0 == rawDelta & (1 << (DELTA_BITS - 1))) {
            // Non-negative power
            delta = DELTA_BASE.pow(rawDelta);
        }
        else {
            // Negative power, converting from two's complement
            delta = ABDK_ONE.div(DELTA_BASE.pow(DELTA_MODULO - rawDelta));
        }

        uint256 basePrice = prices[id];
        return delta.mulu(basePrice);
    }


    function checkUpdateAccess(uint32 epochId_, uint32 previousEpochId_,
                               uint256[] calldata metricIds_, uint256[] calldata prices_, bytes calldata deltas_,
                               uint8 v, bytes32 r, bytes32 s)
        internal
        virtual
        view
    {
        checkMessageSignature(keccak256(abi.encode(
                UPDATE_TYPE_HASH, epochId_, previousEpochId_,
                keccak256(abi.encodePacked(metricIds_)), keccak256(abi.encodePacked(prices_)), keccak256(deltas_)
            )),
            v, r, s);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./IVersioned.sol";


/// @title Reader of MultidataFeeds core data.
interface ICoreMultidataFeedsReader is IVersioned {

    struct Metric {
        string name;    // unique, immutable in a contract
        string description;
        string currency;    // USD, ETH, PCT (for percent), BPS (for basis points), etc
        string[] tags;
    }

    struct Quote {
        uint256 value;
        uint32 updateTS;
    }

    event NewMetric(string name);
    event MetricInfoUpdated(string name);
    /// @notice updated one metric or all if metricId=type(uint256).max-1
    event MetricUpdated(uint indexed epochId, uint indexed metricId);


    /**
     * @notice Gets a list of metrics quoted by this oracle.
     * @return A list of metric info indexed by numerical metric ids.
     */
    function getMetrics() external view returns (Metric[] memory);

    /// @notice Gets a count of metrics quoted by this oracle.
    function getMetricsCount() external view returns (uint);

    /// @notice Gets metric info by a numerical id.
    function getMetric(uint256 id) external view returns (Metric memory);

    /**
     * @notice Checks if a metric is quoted by this oracle.
     * @param name Metric codename.
     * @return has `true` if metric exists.
     * @return id Metric numerical id, set if `has` is true.
     */
    function hasMetric(string calldata name) external view returns (bool has, uint256 id);

    /**
     * @notice Gets last known quotes for specified metrics.
     * @param names Metric codenames to query.
     * @return quotes Values and update timestamps for queried metrics.
     */
    function quoteMetrics(string[] calldata names) external view returns (Quote[] memory quotes);

    /**
     * @notice Gets last known quotes for specified metrics by internal numerical ids.
     * @dev Saves one storage lookup per metric.
     * @param ids Numerical metric ids to query.
     * @return quotes Values and update timestamps for queried metrics.
     */
    function quoteMetrics(uint256[] calldata ids) external view returns (Quote[] memory quotes);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./interfaces/public/ICoreMultidataFeedsReader.sol";


abstract contract AbstractFeedsWithMetrics is ICoreMultidataFeedsReader {

    Metric[] internal metrics;
    // Position of the metric in the `metrics` array, plus 1 because index 0
    // means that metric is not exists (to avoid additional checks of existence).
    mapping(string => uint) internal adjustedMetricId;

    /// @inheritdoc ICoreMultidataFeedsReader
    function getMetrics() public view override returns (Metric[] memory) {
        return metrics;
    }

    /// @inheritdoc ICoreMultidataFeedsReader
    function getMetricsCount() public view override returns (uint) {
        return metrics.length;
    }

    /// @inheritdoc ICoreMultidataFeedsReader
    function getMetric(uint256 id) external view override returns (Metric memory) {
        require(id < metrics.length, "MultidataFeeds: METRIC_NOT_FOUND");
        return metrics[id];
    }

    /// @inheritdoc ICoreMultidataFeedsReader
    function hasMetric(string calldata name) public view override returns (bool has, uint256 id) {
        uint adjustedId = adjustedMetricId[name];
        if (adjustedId != 0) {
            return (true, adjustedId - 1);
        }

        return (false, 0);
    }

    function addMetric(Metric memory metric_) internal returns (uint newMetricId_) {
        uint adjustedId = adjustedMetricId[metric_.name];
        require(adjustedId == 0, "MultidataFeeds: METRIC_EXISTS");

        newMetricId_ = metrics.length;
        adjustedMetricId[metric_.name] = newMetricId_ + 1;
        metrics.push(metric_);

        emit NewMetric(metric_.name);
    }

    function updateMetric(Metric memory metric_) internal {
        uint adjustedId = adjustedMetricId[metric_.name];
        require(adjustedId != 0, "MultidataFeeds: METRIC_NOT_FOUND");

        metrics[adjustedId-1] = metric_;
        emit MetricInfoUpdated(metric_.name);
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MultipartyCommons.sol";


abstract contract NonProxiedOwnerMultipartyCommons is MultipartyCommons {
    event MPOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    OwnerMultisignature internal ownerMultisignature_; // informational field
    address internal mpOwner_;   // described by ownerMultisignature

    constructor(address verifyingContract, uint256 chainId) MultipartyCommons(verifyingContract, chainId) {
        address[] memory newParticipants = new address[](1);
        newParticipants[0] = msg.sender;
        changeOwner_(msg.sender, 1, newParticipants);
    }

    /**
     * @notice Changes multiparty owner data.
     * @param newOwner Address of the new mp owner.
     * @param quorum New quorum value.
     * @param newParticipants List of the new participants' addresses
     * @param salt Salt value
     * @param deadline Unix ts at which the work must be interrupted.
     */
    function changeOwner(address newOwner, uint quorum, address[] calldata newParticipants, uint salt, uint deadline)
        external
        selfCall
        applicable(salt, deadline)
    {
        changeOwner_(newOwner, quorum, newParticipants);
    }

    /**
     * @notice Changes multiparty owner data. Internal
     * @param newOwner Address of the new mp owner.
     * @param quorum New quorum value.
     * @param newParticipants List of the new participants' addresses
     */
    function changeOwner_(address newOwner, uint quorum, address[] memory newParticipants)
        internal
    {
        require(newOwner != address(0), "MP: ZERO_ADDRESS");
        emit MPOwnershipTransferred(mpOwner_, newOwner);
        address[] memory oldParticipants = ownerMultisignature_.participants;
        onNewOwner(newOwner, quorum, newParticipants, oldParticipants);
        ownerMultisignature_.quorum = quorum;
        ownerMultisignature_.participants = newParticipants;
        mpOwner_ = newOwner;
    }

    /**
     * @notice The new mp owner handler. Empty implementation
     * @param newOwner Address of the new mp owner.
     * @param newQuorum New quorum value.
     * @param newParticipants List of the new participants' addresses.
     * @param oldParticipants List of the old participants' addresses.
     */
    function onNewOwner(address newOwner, uint newQuorum, address[] memory newParticipants, address[] memory oldParticipants) virtual internal {}

    // @inheritdoc IMpOwnable
    function ownerMultisignature() public view virtual override returns (OwnerMultisignature memory) {
        return ownerMultisignature_;
    }

    // @inheritdoc IMpOwnable
    function mpOwner() public view virtual override returns (address) {
        return mpOwner_;
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;


/// @title Contract supporting versioning using SemVer version scheme.
interface IVersioned {
    /// @notice Contract version, using SemVer version scheme.
    function VERSION() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IMpOwnable.sol";


abstract contract MultipartyCommons is IMpOwnable {
    bytes32 immutable internal VOTE_TYPE_HASH;
    bytes32 internal DOMAIN_SEPARATOR;

    mapping(uint => bool) public usedSalt;

    // Self-calls are used to engage builtin deserialization facility (abi parsing) and not parse args ourselves
    modifier selfCall virtual {
        require(msg.sender == address(this), "MP: NO_ACCESS");
        _;
    }

    // Checks if a privileged call can be applied
    modifier applicable(uint salt, uint deadline) virtual {
        require(getTimeNow() <= deadline, "MP: DEADLINE");
        require(!usedSalt[salt], "MP: DUPLICATE");
        usedSalt[salt] = true;
        _;
    }

    constructor(address verifyingContract, uint256 chainId) {
        require(verifyingContract != address(0) && chainId != 0, 'MP: Invalid domain parameters');
        VOTE_TYPE_HASH = keccak256("Vote(bytes calldata)");
        setDomainSeparator(verifyingContract, chainId);
    }

    /**
     * @notice DOMAIN_SEPARATOR setter.
     * @param verifyingContract Address of the verifying contract
     * @param chainId Chain id of the verifying contract
     */
    function setDomainSeparator(address verifyingContract, uint256 chainId) internal {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Multidata.Multiparty.Protocol")),
                keccak256(bytes("1")),
                chainId,
                verifyingContract
            )
        );
    }

    /**
     * @notice Performs privileged call to the contract.
     * @param privilegedCallData Method calldata
     * @param v Signature v for the call
     * @param r Signature r for the call
     * @param s Signature s for the call
     */
    function privilegedCall(bytes calldata privilegedCallData, uint8 v, bytes32 r, bytes32 s) external
    {
        checkMessageSignature(keccak256(abi.encode(VOTE_TYPE_HASH, keccak256(privilegedCallData))), v, r, s);

        (bool success, bytes memory returnData) = address(this).call(privilegedCallData);
        if (!success) {
            revert(string(returnData));
        }
    }

    /**
     * @notice Checks the message signature.
     * @param hashStruct Hash of a message struct
     * @param v V of the message signature
     * @param r R of the message signature
     * @param s S of the message signature
     */
    function checkMessageSignature(bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal virtual view {
        require(ECDSA.recover(generateMessageHash(hashStruct), v, r, s) == mpOwner(), "MP: NO_ACCESS");
    }

    /**
     * @notice Returns hash of the message for the hash of the struct.
     * @param hashStruct Hash of a message struct
     */
    function generateMessageHash(bytes32 hashStruct) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashStruct
            )
        );
    }

    /**
     * @notice Returns current chain time in unix ts.
     */
    function getTimeNow() virtual internal view returns (uint32) {
        return uint32(block.timestamp);
    }

    // @inheritdoc IMpOwnable
    function ownerMultisignature() public view virtual override returns (OwnerMultisignature memory);

    // @inheritdoc IMpOwnable
    function mpOwner() public view virtual override returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMpOwnable {
    struct OwnerMultisignature {
        uint quorum;
        address[] participants;
    }

    // @notice Returns OwnerMultisignature data
    function ownerMultisignature() external view returns (OwnerMultisignature memory);

    // @notice Returns address og the multiparty owner
    function mpOwner() external view returns (address);
}