// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import {IPlease} from "./IPlease.sol";
// import {OpenPositionInfo, Open} from "./IMarketTrade.sol";

// Uncomment this line to use co\nsole.log
// import "hardhat/console.sol";

contract Please {

    struct OpenPositionInfo {
    uint256 id;
    uint256 openVersion;
    int256  qty;
    uint256 openTimestamp;
    uint256 takerMargin;
    uint256 makerMargin;
    uint256 tradingFee;
}

struct Open {
    uint256 id;
    uint256 openVersion;
}

    event Open1(Open[] position);
    event Open2(Open[] position, address marketAddress);
    event Open3(Open[] position, address indexed marketAddress);
    event Open4(address marketAddress, OpenPositionInfo position);
    event Open5(address indexed marketAddress, OpenPositionInfo position);
    event Open6(OpenPositionInfo position, uint256 marketAddress);
    event Open7(OpenPositionInfo position, uint256 indexed marketAddress);
    event Open8(uint256 marketAddress, OpenPositionInfo position);
    event Open9(uint256 indexed marketAddress, OpenPositionInfo position);


    event Open10(Open position, uint256 marketAddress);
    event Open11(Open position, uint256 indexed marketAddress);

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

        Open memory info2 = Open({
            id: 1,
            openVersion: 2
        });

        Open[] memory infos2 = new Open[](1);
        infos2[0] = info2;

        emit Open1(infos2);
        emit Open2(infos2, address(this));
        emit Open3(infos2, address(this));
        emit Open4(address(this), info);
        emit Open5(address(this), info);
        emit Open6(info, 1);
        emit Open7(info, 1);
        emit Open8(1, info);
        emit Open9(1, info);
        emit Open10(info2, 1);
        emit Open11(info2, 1);

        emit OpenPosition(address(this), 123, info);
        emit PositionOpen(info, address(this), 123);
        emit OpenPositionNonIndexed(address(this), 123, info);
        emit PositionOpenNonIndexed(info, address(this), 123);
        emit InfoPosition(address(this), 123, 1, 2, 3, 4, 5, 6, 7);
        emit PositionInfo(1, 2, 3, 4, 5, 6, 7, address(this), 123);
    }
}