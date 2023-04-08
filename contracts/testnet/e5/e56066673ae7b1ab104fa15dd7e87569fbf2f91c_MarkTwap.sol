/**
 *Submitted for verification at Arbiscan on 2023-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

interface IMarkPriceOracle {
    function getCustomMarkTwap(
        uint256 _index,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external view returns (uint256 priceCumulative);
}

contract MarkTwap {
    uint256 public markPrice;

    function setMarkTwap(IMarkPriceOracle _markOracle, uint256 _start, uint256 _end) external {
        markPrice = _markOracle.getCustomMarkTwap(0, _start, _end);
    }
}