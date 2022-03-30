//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;
pragma abicoder v2;

library TidePoolMath {

    int24 internal constant MAX_TICK = 887272;
    int24 internal constant MIN_TICK = -MAX_TICK;

    struct Ratio {
        uint256 n;
        uint256 d;
    }

    function calculateWindow(int24 tick, int24 tickSpacing, uint8 window, uint8 bias) public pure returns (int24 tickUpper, int24 tickLower) {
        int24 windowSize = abs(tick * window / 100);

        tickUpper = (tick + windowSize * bias / 100) / tickSpacing * tickSpacing;
        tickLower = (tick - windowSize * (100-bias) / 100) / tickSpacing * tickSpacing;

        // fix some corner cases
        if(tickUpper <= tick) tickUpper = tick + tickSpacing;
        if(tickLower >= tick) tickLower = tick - tickSpacing;
        if(tickUpper > MAX_TICK) tickUpper = MAX_TICK - tickSpacing;
        if(tickLower < MIN_TICK) tickLower = MIN_TICK + tickSpacing;

        require(tickUpper % tickSpacing == 0,"TU");
        require(tickLower % tickSpacing == 0,"TL");
    }

    function calculateDeltaRatio(Ratio memory current, Ratio memory desired) public pure returns (bool zeroForOne, Ratio memory delta) {
        require(current.n > 0 || current.d > 0,"NZ");

        // convert the ratios into 0 - 100 values
        current = Ratio({ n: current.n * 100 / (current.n + current.d), d: current.d * 100 / (current.n + current.d)});
        desired = Ratio({ n: desired.n * 100 / (desired.n + desired.d), d: desired.d * 100 / (desired.n + desired.d)});

        zeroForOne = current.n > desired.n;

        uint256 diff = zeroForOne ? difference(current.n, desired.n) : difference(current.d, desired.d);

        delta.n = zeroForOne? diff * current.n / 100 : diff * current.d / 100;
        delta.d = 100;
    }

    // overflow/underflow protection
    function difference(uint256 zero, uint256 one) public pure returns (uint256) {
        return zero >= one ? zero - one : one - zero;
    }

    // normalize on a scale of 0 - 100
    function normalizeRange(int24 v, int24 min, int24 max) public pure returns (uint256) {
        require(v >= min && v <= max && max > min,"II");
        return uint256((v - min) * 100 / (max - min));
    }

    // absolute value
    function abs(int24 i) public pure returns (int24) {
        return i > 0 ? i : -i;
    }
}