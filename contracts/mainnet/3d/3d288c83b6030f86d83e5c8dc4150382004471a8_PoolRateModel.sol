// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract PoolRateModel {
    uint256 public immutable kink; // spot in the curve where high rate kicks in
    uint256 public immutable base; // base / minimum rate
    uint256 public immutable low; // low rate (below kink)
    uint256 public immutable high; // high rate (above kink)

    constructor(uint256 _kink, uint256 _base, uint256 _low, uint256 _high) {
        kink = _kink;
        base = _base;
        low = _low;
        high = _high;
    }

    // amt - percent pool utilization (1e18)
    function rate(uint256 amt) public view returns (uint256) {
        if (amt <= kink) {
            return base + (low * amt / 1e18);
        } else {
            return base + (low * kink / 1e18) + (high * (amt - kink) / 1e18);
        }
    }
}