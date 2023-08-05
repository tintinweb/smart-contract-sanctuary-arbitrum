// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct OpenPositionInfo {
    uint256 id;
    uint256 openVersion;
    int256  qty;
    uint256 openTimestamp;
    uint256 takerMargin;
    uint256 makerMargin;
    uint256 tradingFee;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {OpenPositionInfo} from "./IMarketTrade.sol";

interface IPlease {

   event OpenPositionNonIndexed(
        address marketAddress,
        uint256 positionId,
        OpenPositionInfo position
    );

     event PositionOpenNonIndexed(
        OpenPositionInfo position,
        address marketAddress,
        uint256 positionId
    );

    event OpenPosition(
        address indexed marketAddress,
        uint256 indexed positionId,
        OpenPositionInfo position
    );

    event PositionOpen(
        OpenPositionInfo position,
        address indexed marketAddress,
        uint256 indexed positionId
    );

    event InfoPosition(
        address indexed marketAddress,
        uint256 indexed positionId,
        uint256 id,
        uint256 openVersion,
        int256 qty,
        uint256 openTimestamp,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 tradingFee
    );

    event PositionInfo(
        uint256 id,
        uint256 openVersion,
        int256 qty,
        uint256 openTimestamp,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 tradingFee,
        address indexed marketAddress,
        uint256 indexed positionId
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPlease} from "./IPlease.sol";
import {OpenPositionInfo} from "./IMarketTrade.sol";

// Uncomment this line to use co\nsole.log
// import "hardhat/console.sol";

contract Please is IPlease {
    function run() external {
        OpenPositionInfo memory info = OpenPositionInfo({
            id: 1,
            openVersion: 2,
            qty: 3,
            openTimestamp: 4,
            takerMargin: 5,
            makerMargin: 6,
            tradingFee: 7
        });

        emit OpenPosition(address(this), 123, info);
        emit PositionOpen(info, address(this), 123);
        emit OpenPositionNonIndexed(address(this), 123, info);
        emit PositionOpenNonIndexed(info, address(this), 123);
        emit InfoPosition(address(this), 123, 1, 2, 3, 4, 5, 6, 7);
        emit PositionInfo(1, 2, 3, 4, 5, 6, 7, address(this), 123);
    }
}