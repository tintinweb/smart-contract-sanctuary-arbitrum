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
        int256 qty;
        uint256 openTimestamp;
        uint256 takerMargin;
        uint256 makerMargin;
        uint256 tradingFee;
    }

    struct Open {
        uint256 id;
        uint256 openVersion;
    }

    event Open1(Open[]);
    event Open2(Open[], address);
    event Open3(Open[], address indexed);
    event Open4(address, OpenPositionInfo);
    event Open5(address indexed, OpenPositionInfo);
    event Open6(OpenPositionInfo, uint256);
    event Open7(OpenPositionInfo, uint256 indexed);
    event Open8(uint256, OpenPositionInfo);
    event Open9(uint256 indexed, OpenPositionInfo);

    event Open10(Open position, uint256);
    event Open11(Open position, uint256 indexed);

    event OpenPositionNonIndexed(address, uint256, OpenPositionInfo);

    event PositionOpenNonIndexed(OpenPositionInfo, address, uint256);

    event OpenPosition(
        address indexed,
        uint256 indexed positionId,
        OpenPositionInfo
    );

    event PositionOpen(
        OpenPositionInfo,
        address indexed,
        uint256 indexed positionId
    );

    event InfoPosition(
        address indexed,
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
        address indexed,
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

        Open memory info2 = Open({id: 1, openVersion: 2});

        Open[] memory infos2 = new Open[](1);
        infos2[0] = info2;

        emit InfoPosition(address(this), 123, 1, 2, 3, 4, 5, 6, 7);
        emit PositionInfo(1, 2, 3, 4, 5, 6, 7, address(this), 123);

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
    }
}