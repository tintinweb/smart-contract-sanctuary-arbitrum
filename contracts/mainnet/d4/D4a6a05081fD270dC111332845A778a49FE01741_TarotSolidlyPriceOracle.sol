pragma solidity =0.5.16;

import "./libraries/UQ112x112.sol";
import "./interfaces/ISolidlyBaseV1Pair.sol";
import "./interfaces/ITarotSolidlyPriceOracle.sol";

contract TarotSolidlyPriceOracle is ITarotSolidlyPriceOracle {
    using UQ112x112 for uint224;

    uint32 public constant MIN_T = 1200;

    struct ReserveInfo {
        uint256 reserve0CumulativeSlotA;
        uint256 reserve1CumulativeSlotA;
        uint256 reserve0CumulativeSlotB;
        uint256 reserve1CumulativeSlotB;
        uint32 lastUpdateSlotA;
        uint32 lastUpdateSlotB;
        bool latestIsSlotA;
        bool initialized;
    }
    mapping(address => ReserveInfo) public getReserveInfo;

    function getPair(address pair)
        external
        view
        returns (
            uint256 priceCumulativeSlotA,
            uint256 priceCumulativeSlotB,
            uint32 lastUpdateSlotA,
            uint32 lastUpdateSlotB,
            bool latestIsSlotA,
            bool initialized
        )
    {
        priceCumulativeSlotA;
        priceCumulativeSlotB;
        ReserveInfo storage reserveInfoStorage = getReserveInfo[pair];
        (lastUpdateSlotA, lastUpdateSlotB, latestIsSlotA, initialized) = (
            reserveInfoStorage.lastUpdateSlotA,
            reserveInfoStorage.lastUpdateSlotB,
            reserveInfoStorage.latestIsSlotA,
            reserveInfoStorage.initialized
        );
    }

    function safe112(uint256 n) internal pure returns (uint112) {
        require(n < 2**112, "TarotPriceOracle: SAFE112");
        return uint112(n);
    }

    function initialize(address pair) external {
        ReserveInfo storage reserveInfoStorage = getReserveInfo[pair];
        require(!reserveInfoStorage.initialized, "TarotPriceOracle: ALREADY_INITIALIZED");

        require(!ISolidlyBaseV1Pair(pair).stable(), "TarotPriceOracle: VAMM_ONLY");
        (uint256 reserve0Cumulative, uint256 reserve1Cumulative, ) = ISolidlyBaseV1Pair(pair).currentCumulativePrices();
        uint32 blockTimestamp = getBlockTimestamp();

        reserveInfoStorage.reserve0CumulativeSlotA = reserve0Cumulative;
        reserveInfoStorage.reserve1CumulativeSlotA = reserve1Cumulative;
        reserveInfoStorage.reserve0CumulativeSlotB = reserve0Cumulative;
        reserveInfoStorage.reserve1CumulativeSlotB = reserve1Cumulative;
        reserveInfoStorage.lastUpdateSlotA = blockTimestamp;
        reserveInfoStorage.lastUpdateSlotB = blockTimestamp;
        reserveInfoStorage.latestIsSlotA = true;
        reserveInfoStorage.initialized = true;

        emit ReserveInfoUpdate(pair, reserve0Cumulative, reserve1Cumulative, blockTimestamp, true);
    }

    function getResult(address pair) external returns (uint224 price, uint32 T) {
        ReserveInfo memory reserveInfo = getReserveInfo[pair];
        require(reserveInfo.initialized, "TarotPriceOracle: NOT_INITIALIZED");
        ReserveInfo storage reserveInfoStorage = getReserveInfo[pair];

        uint32 blockTimestamp = getBlockTimestamp();
        uint32 lastUpdateTimestamp = reserveInfo.latestIsSlotA ? reserveInfo.lastUpdateSlotA : reserveInfo.lastUpdateSlotB;
        (uint256 reserve0CumulativeCurrent, uint256 reserve1CumulativeCurrent, ) = ISolidlyBaseV1Pair(pair).currentCumulativePrices();

        uint256 reserve0CumulativeLast;
        uint256 reserve1CumulativeLast;

        if (blockTimestamp - lastUpdateTimestamp >= MIN_T) {
            // update price
            if (reserveInfo.latestIsSlotA) {
                reserve0CumulativeLast = reserveInfo.reserve0CumulativeSlotA;
                reserve1CumulativeLast = reserveInfo.reserve1CumulativeSlotA;

                reserveInfoStorage.reserve0CumulativeSlotB = reserve0CumulativeCurrent;
                reserveInfoStorage.reserve1CumulativeSlotB = reserve1CumulativeCurrent;
                reserveInfoStorage.lastUpdateSlotB = blockTimestamp;
                reserveInfoStorage.latestIsSlotA = false;
                emit ReserveInfoUpdate(pair, reserve0CumulativeCurrent, reserve1CumulativeCurrent, blockTimestamp, false);
            } else {
                reserve0CumulativeLast = reserveInfo.reserve0CumulativeSlotB;
                reserve1CumulativeLast = reserveInfo.reserve1CumulativeSlotB;

                reserveInfoStorage.reserve0CumulativeSlotA = reserve0CumulativeCurrent;
                reserveInfoStorage.reserve1CumulativeSlotA = reserve1CumulativeCurrent;
                reserveInfoStorage.lastUpdateSlotA = blockTimestamp;
                reserveInfoStorage.latestIsSlotA = true;
                emit ReserveInfoUpdate(pair, reserve0CumulativeCurrent, reserve1CumulativeCurrent, blockTimestamp, true);
            }
        } else {
            // don't update; return price using previous priceCumulative
            if (reserveInfo.latestIsSlotA) {
                lastUpdateTimestamp = reserveInfo.lastUpdateSlotB;
                reserve0CumulativeLast = reserveInfo.reserve0CumulativeSlotB;
                reserve1CumulativeLast = reserveInfo.reserve1CumulativeSlotB;
            } else {
                lastUpdateTimestamp = reserveInfo.lastUpdateSlotA;
                reserve0CumulativeLast = reserveInfo.reserve0CumulativeSlotA;
                reserve1CumulativeLast = reserveInfo.reserve1CumulativeSlotA;
            }
        }

        T = blockTimestamp - lastUpdateTimestamp; // overflow is desired
        require(T >= MIN_T, "TarotPriceOracle: NOT_READY"); //reverts only if the pair has just been initialized
        // / is safe, and - overflow is desired
        uint112 twapReserve0 = safe112((reserve0CumulativeCurrent - reserve0CumulativeLast) / T);
        uint112 twapReserve1 = safe112((reserve1CumulativeCurrent - reserve1CumulativeLast) / T);

        price = UQ112x112.encode(twapReserve1).uqdiv(twapReserve0);
    }

    /*** Utilities ***/

    function getBlockTimestamp() public view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }
}

pragma solidity =0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

pragma solidity >=0.5;

interface ISolidlyBaseV1Pair {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function reserve0CumulativeLast() external view returns (uint256);

    function reserve1CumulativeLast() external view returns (uint256);

    function currentCumulativePrices()
        external
        view
        returns (
            uint256 reserve0Cumulative,
            uint256 reserve1Cumulative,
            uint256 blockTimestamp
        );

    function stable() external view returns (bool);

    function observationLength() external view returns (uint256);

    function observations(uint256) external view returns (uint256 timestamp, uint256 reserve0Cumulative, uint256 reserve1Cumulative);
}

pragma solidity >=0.5;

interface ITarotSolidlyPriceOracle {
    function MIN_T() external pure returns (uint32);

    function getReserveInfo(address pair)
        external
        view
        returns (
            uint256 reserve0CumulativeSlotA,
            uint256 reserve1CumulativeSlotA,
            uint256 reserve0CumulativeSlotB,
            uint256 reserve1CumulativeSlotB,
            uint32 lastUpdateSlotA,
            uint32 lastUpdateSlotB,
            bool latestIsSlotA,
            bool initialized
        );

    function initialize(address pair) external;

    function getResult(address pair) external returns (uint224 price, uint32 T);

    function getBlockTimestamp() external view returns (uint32);

    event ReserveInfoUpdate(address indexed pair, uint256 reserve0Cumulative, uint256 reserve1Cumulative, uint32 blockTimestamp, bool latestIsSlotA);
}