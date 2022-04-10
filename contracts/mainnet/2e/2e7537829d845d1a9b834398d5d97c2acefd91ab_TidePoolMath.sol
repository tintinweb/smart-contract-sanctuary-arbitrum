//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;
pragma abicoder v2;

library TidePoolMath {

    int24 internal constant MAX_TICK = 887272;
    int24 internal constant MIN_TICK = -MAX_TICK;

    function calculateWindow(int24 tick, int24 tickSpacing, int24 window, uint8 bias) public pure returns (int24 tickUpper, int24 tickLower) {
        require(bias >= 0 && bias <= 100,"BB");
        window = window < 1 ? 1 : window;
        int24 windowSize = window * tickSpacing;

        tickUpper = (tick + windowSize * bias / 100);
        tickLower = (tick - windowSize * (100-bias) / 100);

        // fix some corner cases
        if(tickUpper < tick) tickUpper = tick;
        if(tickLower > tick) tickLower = tick;
        if(tickUpper > MAX_TICK) tickUpper = (MAX_TICK / tickSpacing - 1) * tickSpacing;
        if(tickLower < MIN_TICK) tickLower = (MIN_TICK / tickSpacing + 1) * tickSpacing;

        // make sure these are valid ticks
        tickUpper = tickUpper / tickSpacing * tickSpacing;
        tickLower = tickLower / tickSpacing * tickSpacing;
    }

    // normalize on a scale of 0 - 100
    function normalizeRange(int24 v, int24 min, int24 max) public pure returns (uint256) {
        require(v >= min && v <= max && max > min,"II");
        return uint256((v - min) * 100 / (max - min));
    }

    // find the greater ratio: a:b or c:d.
    // assumption: a >= b and c >= d
    function proportion(uint256 a, uint256 b, uint256 c, uint256 d) public pure returns (bool) {
        uint256 first = a > 0 ? (a - b) / a : 0;
        uint256 second = c > 0 ? (c - d) / c : 0;
        return  first >= second ? true : false;
    }
}