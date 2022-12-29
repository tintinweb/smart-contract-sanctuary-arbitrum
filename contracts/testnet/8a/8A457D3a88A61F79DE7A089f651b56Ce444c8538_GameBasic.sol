pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: Unlicense

import "../libraries/Map.sol";
//import "../libraries/Map2.sol";
import "hardhat/console.sol";

contract TestMap {
    function genTile(string calldata seed,uint tilePos, uint mapSize) public returns(uint) {
        uint tile = Map.genTile(uint(keccak256(bytes(seed))), tilePos, mapSize);
        return tile;
    }

    function genTile2(string calldata seed,uint tilePos, uint mapSize) public returns(bool[64] memory results) {
        uint tile = Map.genTile(uint(keccak256(bytes(seed))), tilePos, mapSize);
        for(uint i = 0; i < 64; i++) {
            results[i] = ((tile >> (i * 4)) & 0xf) > 0;
        }
    }
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

library Map {

    struct Rect {
        uint x1;
        uint y1;
        uint x2;
        uint y2;
    }
    
    function genTile(uint mapSeed, uint tilePos, uint mapSize) internal pure returns(uint result) {
        require(mapSize % 8 == 0, "invalid map size");
        uint mapSize16 = mapSize % 16 == 0 ? mapSize : mapSize + 8;
        uint tileX = tilePos % (mapSize/ 8);
        uint tileY = tilePos / (mapSize/ 8);
        for(uint i = 0; i < 5; i++) {
            result |= genTileWaterByOneStep(uint(keccak256(abi.encodePacked(mapSeed,bytes("water"),tileX / 2 + mapSize16 / 16 * tileY / 2, i))), tileX % 2, tileY % 2, 16);
        }

        result = genMountain(uint(keccak256(abi.encodePacked(mapSeed, bytes("mountain"),tilePos))), result);

        result = genWall(uint(keccak256(abi.encodePacked(mapSeed, bytes("wall"),tileX / 2 + mapSize16 / 16 * tileY / 2))), int(tileX % 2), int(tileY % 2), 16, result);

        result = genChestBox(uint(keccak256(abi.encodePacked(mapSeed, bytes("mountain"), tilePos))), result);

        return result;
    }

    function isEmptyTile(uint curMap, uint tilePos) internal pure returns(bool) {
        return (curMap >> (4 * tilePos)) & 0xf == 0;
    }

    function genMountain(uint seed, uint curMap) private pure returns(uint) {
        uint index;
        uint x;
        uint y;
        uint pos;
        if (seed % 100 < 50) {
            index = (seed >> 8) % 25;
            x = index % 5;
            y = index / 5;
            uint bigMountain = 0;
            pos = y * 8 + x;
            for (uint i = 0; i < 9; i++) {
                if (isEmptyTile(curMap, pos)) {
                    bigMountain |= 2 << (4 * pos);
                } else {
                    bigMountain = 0;
                    break;
                }
                pos += (i+1) % 3 == 0 ? 6 : 1;
            }
            curMap |= bigMountain;
        }
        uint singleCount = (seed >> 16) % (seed % 100 < 50 ? 6 : 9);
        for (uint i = 0; i < singleCount; i++) {
            pos = (seed >> (24 + i * 6)) % 64;
            if (pos >= 8 && isEmptyTile(curMap, pos) && isEmptyTile(curMap, pos-8)) {
                curMap |= 2 << (4 * pos);
                curMap |= 2 << (4 * (pos - 8));
            }
        }

        singleCount = (seed >> 160) % (seed % 100 < 50 ? 4 : 6);
        for (uint i = 0; i < singleCount; i++) {
            pos = (seed >> (164 + i * 6)) % 64;
            if (isEmptyTile(curMap, pos)) {
                curMap |= 2 << (4 * pos);
            }
        }
        return curMap;
    }

    function genWall(uint seed, int tileX, int tileY, uint mapSize, uint curMap) private pure returns(uint) {
        uint wallLineCount = seed % 4 + 1;
        for (uint i = 0; i < wallLineCount; i++) {
            int x = int((seed >> (2 + i * 16)) % (mapSize * mapSize));
            int y = x / int(mapSize);
            x %= int(mapSize);
            for (uint j = 0; j < 4; j++) {
                int dx = (seed >> (100 + (4 * i + j) * 2)) % 2 == 0 ? int(1) : int(-1);
                int dy = 0;
                if (j % 2 != 0) {
                    (dx, dy) = (dy, dx);
                }
                uint count = (seed >> (160 + (4 * i + j) * 4)) % 10;
                for (uint m = 0; m < count; m++) {
                    x += dx;
                    y += dy;
                    if (x >= tileX * 8 && x < tileX * 8 + 8 && y >= tileY * 8 && y < tileY * 8 + 8) {
                        uint pos = uint((x - tileX * 8) + (y - tileY * 8) * 8);
                        if (isEmptyTile(curMap, pos)) {
                            curMap |= 3 << (4 * pos);
                        }
                    }
                }
            }
        }
        return curMap;
    }

    function genChestBox(uint seed, uint curMap) private pure returns(uint) {
        uint singleCount = seed % 3;
        for (uint i = 0; i < singleCount; i++) {
            uint pos = (seed >> (24 + i * 6)) % 64;
            if (isEmptyTile(curMap, pos)) {
                curMap |= 4 << (4 * pos);
            }
        }
        return curMap;
    }

    function genTileWaterByOneStep(uint seed, uint tileX, uint tileY, uint mapSize) private pure returns(uint) {
        Rect memory curMap = Rect({
            x1: tileX * 8,
            y1: tileY * 8,
            x2: tileX * 8 + 8,
            y2: tileY * 8 + 8
        });
        uint cx = seed % (mapSize * mapSize);
        uint cy = cx / mapSize;
        cx %= mapSize;

        uint[8] memory all_f = [
            (seed >> 0) % 64, 
            (seed >> 6) % 64,
            (seed >> 12) % 64,
            (seed >> 18) % 64,
            (seed >> 24) % 64,
            (seed >> 30) % 64,
            (seed >> 36) % 64,
            (seed >> 42) % 64
        ];
        Rect memory fullMap = Rect(0, 0, 0, 0);
        uint[4] memory f;

        uint water = 0;

        fullMap.x1 = 0;
        fullMap.y1 = 0;
        fullMap.x2 = cx;
        fullMap.y2 = cy;
        f[0] = all_f[0];
        f[1] = all_f[1];
        f[2] = 99;
        f[3] = all_f[3];
        water |= interpolate(fullMap, curMap, f);

        fullMap.x1 = cx;
        fullMap.y1 = 0;
        fullMap.x2 = mapSize;
        fullMap.y2 = cy;
        f[0] = all_f[1];
        f[1] = all_f[2];
        f[2] = all_f[4];
        f[3] = 99;
        water |= interpolate(fullMap, curMap, f);

        fullMap.x1 = 0;
        fullMap.y1 = cy;
        fullMap.x2 = cx;
        fullMap.y2 = mapSize;
        f[0] = all_f[3];
        f[1] = 99;
        f[2] = all_f[6];
        f[3] = all_f[5];
        water |= interpolate(fullMap, curMap, f);

        fullMap.x1 = cx;
        fullMap.y1 = cy;
        fullMap.x2 = mapSize;
        fullMap.y2 = mapSize;
        f[0] = 99;
        f[1] = all_f[4];
        f[2] = all_f[7];
        f[3] = all_f[6];
        water |= interpolate(fullMap, curMap, f);

        return water;
    }

    function interpolate(Rect memory fullMap, Rect memory curMap, uint[4] memory f) private pure returns(uint result) {
        Rect memory intersect = Rect({
            x1: fullMap.x1 > curMap.x1 ? fullMap.x1 : curMap.x1,
            y1: fullMap.y1 > curMap.y1 ? fullMap.y1 : curMap.y1,
            x2: fullMap.x2 < curMap.x2 ? fullMap.x2 : curMap.x2,
            y2: fullMap.y2 < curMap.y2 ? fullMap.y2 : curMap.y2
        });

        if (intersect.x1 >= intersect.x2 || intersect.y1 >= intersect.y2) return 0;
        uint w = fullMap.x2 - fullMap.x1;
        uint h = fullMap.y2 - fullMap.y1;
        
        for (uint j = intersect.y1; j < intersect.y2; j++) {
            for (uint i = intersect.x1; i < intersect.x2; i++) {
                uint s = (i - fullMap.x1) * 100 / w;
                uint t = (j - fullMap.y1) * 100 / h;
                uint r = (100 - s) * (100 - t) * f[0] + s * (100-t)*f[1] + s * t * f[2] + (100 - s) * t * f[3];
                // uint s = (i - fullMap.x1);
                // uint t = (j - fullMap.y1);
                // uint r = s+t;
                if (r > 850000) {
                    result |= 1 << (4 * ((j - curMap.y1) * 8 + i - curMap.x1));
                }
            }
        }

    }

    //uint constant TargetF = 85;

    // function genTile8x8ByOneStep2(uint seed, uint tileX, uint tileY, uint mapSize) private view returns(uint) {
    //     Rect memory curMap = Rect({
    //         x1: tileX * 8,
    //         y1: tileY * 8,
    //         x2: tileX * 8 + 8,
    //         y2: tileY * 8 + 8
    //     });
    //     uint cx = seed % (mapSize * mapSize);
    //     uint cy = cx / mapSize;
    //     cx %= mapSize;

    //     uint[4] memory f = [
    //         (seed >> 0) % 64, 
    //         (seed >> 6) % 64,
    //         (seed >> 12) % 64,
    //         (seed >> 18) % 64
    //     ];
    //     uint i;
    //     uint j;

    //     uint a = (99 - TargetF) * cx / (99 - f[1]);
    //     uint b = (99 - TargetF) * cy / (99 - f[0]);

    //     for(i = 0; i < a; i++) {
    //         for(j = 0; j < b; j++) {

    //         }
    //     }

    //     Rect memory fullMap = Rect(0, 0, 0, 0);
    //     uint[4] memory f;

    //     uint water = 0;

    //     fullMap.x1 = 0;
    //     fullMap.y1 = 0;
    //     fullMap.x2 = cx;
    //     fullMap.y2 = cy;
    //     f[0] = all_f[0];
    //     f[1] = all_f[1];
    //     f[2] = 99;
    //     f[3] = all_f[3];
    //     water |= interpolate(fullMap, curMap, f);

    //     fullMap.x1 = cx;
    //     fullMap.y1 = 0;
    //     fullMap.x2 = mapSize;
    //     fullMap.y2 = cy;
    //     f[0] = all_f[1];
    //     f[1] = all_f[2];
    //     f[2] = all_f[4];
    //     f[3] = 99;
    //     water |= interpolate(fullMap, curMap, f);

    //     fullMap.x1 = 0;
    //     fullMap.y1 = cy;
    //     fullMap.x2 = cx;
    //     fullMap.y2 = mapSize;
    //     f[0] = all_f[3];
    //     f[1] = 99;
    //     f[2] = all_f[6];
    //     f[3] = all_f[5];
    //     water |= interpolate(fullMap, curMap, f);

    //     fullMap.x1 = cx;
    //     fullMap.y1 = cy;
    //     fullMap.x2 = mapSize;
    //     fullMap.y2 = mapSize;
    //     f[0] = 99;
    //     f[1] = all_f[4];
    //     f[2] = all_f[7];
    //     f[3] = all_f[6];
    //     water |= interpolate(fullMap, curMap, f);

    //     return water;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./IBattleRoyaleNFT.sol";
import "./BattleRoyaleGameV1.sol";
import "./libraries/Property.sol";

import "hardhat/console.sol";

contract Player is ERC721Holder {

    BattleRoyaleGameV1 private _game;
    IBattleRoyaleNFT private _nft;

    constructor(BattleRoyaleGameV1 game, IBattleRoyaleNFT nft) {
        _game = game;
        _nft = nft;
    }

    function enterGame(GameController mint) external {
        uint[] memory tokenIds = new uint[](2);
        tokenIds[0] = mint.mint(0x11111111111111111111, address(this));
        tokenIds[1] = mint.mint(0x22222222222222222222, address(this));

        _nft.setApprovalForAll(address(_game), true);
        _game.register(tokenIds, address(this));
    }

    function enterGameByCheat(GameController mint) external {
        uint[] memory tokenIds = new uint[](7);
        tokenIds[0] = mint.mint(0x11111111111111111111, address(this));
        mint.characterCheat(tokenIds[0]);

        tokenIds[1] = mint.mint(0x22222222222222222222, address(this));
        tokenIds[2] = mint.mint(0x33333333333333333333, address(this));
        tokenIds[3] = mint.mint(0x44444444444444444444, address(this));
        tokenIds[4] = mint.mint(0x55555555555555555555, address(this));
        tokenIds[5] = mint.mint(0x66666666666666666666, address(this));
        tokenIds[6] = mint.mint(0x77777777777777777777, address(this));

        _nft.setApprovalForAll(address(_game), true);
        _game.register(tokenIds, address(this));
    }

    function actionMove(uint[] calldata path) external {
        _game.actionMove(path);
    }

    function actionBomb(uint tokenIndex, uint targetPos, address[] memory targets, bool[] memory targetsIsPlayer) external {
        _game.actionBomb(tokenIndex, targetPos, targets, targetsIsPlayer);
    }

    function actionEat(uint tokenIndex) external {
        _game.actionEat(tokenIndex);
    }

    function actionShoot(uint tokenIndex, address target, bool targetIsPlayer) external {
        _game.actionShoot(tokenIndex, target, targetIsPlayer);
    }

    function actionPick(uint[] calldata pos, uint[][] calldata tokensIdAndIndex) external {
        _game.actionPick(pos, tokensIdAndIndex);
    }

    function actionDrop(uint pos, uint[] calldata tokenIndexes) external {
        _game.actionDrop(pos, tokenIndexes);
    }

    function actionMoveWithBoots(uint tokenIndex, uint[] calldata path) external {
        _game.actionMoveWithBoots(tokenIndex, path);
    }
}

contract GameController is ERC721Holder {
    event GameStarted();

    Player[] public players;

    bool public started;

    IBattleRoyaleNFT _nft;

    constructor(IBattleRoyaleNFT nft) {
        _nft = nft;
    }

    function mint(uint probability, address to) public returns(uint id) {
        uint seed = uint(
            keccak256(abi.encodePacked(block.timestamp, address(this), _nft.nextTokenId()))
        );
        _nft.mintByGame(to, Property.newProperty(seed, probability));
    }

    function mintMany(address to) public {
        mint(0x11111111111111111111, to);
        mint(0x11111111111111111111, to);
        mint(0x11111111111111111111, to);
        for(uint i = 0; i < 10; i++) {
            mint(0x77665544332222211111, to);
        }
    }

    function characterCheat(uint tokenId) external {
        _nft.setProperty(tokenId, Property.encodeCharacterProperty(100, 100, 6));
    }

    function startGame(BattleRoyaleGameV1 game) external {
        (uint needPlayerCount,,,,,,,,,,,,) = game.config();
        for(uint i = 0; i < needPlayerCount; i++) {
            Player player = new Player(game, _nft);
            if (i == 0) {
                player.enterGameByCheat(this);
            } else {
                player.enterGame(this);
            }
            players.push(player);
        }
        started = true;
        emit GameStarted();
    }

    function startGame2(BattleRoyaleGameV1 game) external {
        (uint needPlayerCount,,,,,,,,,,,,) = game.config();
        for(uint i = 0; i < needPlayerCount-1; i++) {
            Player player = new Player(game, _nft);
            player.enterGame(this);
            players.push(player);
        }
        started = true;
        emit GameStarted();
    }

    function endGame(BattleRoyaleGameV1 game) external {
        game.forceEndGame();
        started = false;

        delete players;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
//import "../lib/forge-std/src/console.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IBattleRoyaleNFT is IERC721Enumerable {
    function tokenType(uint tokenId) external view returns (uint);
    function tokenProperty(uint tokenId) external view returns (uint);
    function nextTokenId() external view returns (uint);

    function burn(uint256 tokenId) external;

    function setProperty(uint tokenId, uint newProperty) external;
    function mintByGame(address to, uint property) external returns (uint);
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;

import "./IBattleRoyaleNFT.sol";
import "./libraries/PlayerDataHelper.sol";
import "./libraries/GameBasic.sol";
import "./libraries/GameConstants.sol";
import "./libraries/GameView.sol";
import "./libraries/GameAction.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./IBattleRoyaleGameV1.sol";
import "./BATTLE.sol";
//import "hardhat/console.sol";
//import "../lib/forge-std/src/console.sol";

contract BattleRoyaleGameV1 is IBattleRoyaleGameV1, Pausable, Ownable, ERC721Holder, ReentrancyGuard  {
    event GameCreated(address indexed addr);
    
    bool private _inited;

    IBattleRoyaleNFT public nft;
    BATTLE public battleToken;
    GameConfig public config;

    address[] public players;
    mapping(address => uint) public playersData;
    mapping(address => address) public signer2player;

    mapping(address => uint) public playersReward;

    mapping(uint => uint) public tilemap;

    mapping(uint => uint) internal _tokensOnGround;

    uint public mapSeed;
    GameState public state;

    // not called when the contract is cloned
    constructor() {
        _inited = true;
    }

    function init(IBattleRoyaleNFT targetNFT, BATTLE targetBattleToken, GameConfig memory initConfig, address newOwner) external checkConfig(initConfig){
        require(_inited == false, "init called");
        _inited = true;
        nft = targetNFT;
        battleToken = targetBattleToken;
        config = initConfig;
        mapSeed = uint(keccak256(abi.encodePacked(address(this), block.timestamp, msg.sender)));
        _transferOwnership(newOwner);
    }

    function clone(IBattleRoyaleNFT targetNFT, BATTLE targetBattleToken, GameConfig memory initConfig) external returns(address) {
        BattleRoyaleGameV1 newGame = BattleRoyaleGameV1(Clones.clone(address(this)));
        newGame.init(targetNFT, targetBattleToken, initConfig, owner());
        emit GameCreated(address(newGame));
        return address(newGame);
    }

    function register(uint[] calldata tokenIds, address signer) external whenNotPaused nonReentrant {
        require(signer2player[signer] == address(0) || signer2player[signer] == msg.sender, "invalid signer");
        signer2player[signer] = msg.sender;
        GameBasic.register(players, playersData, playersReward, _tokensOnGround
        , tilemap, state, GameBasic.RegisterParams({
            nft: nft,
            tokenIds: tokenIds,
            config: config,
            mapSeed: mapSeed,
            player: msg.sender
        }));
        if(players.length == config.needPlayerCount) {
            (mapSeed, state) = GameBasic.startGame(mapSeed, state, config.mapSize, msg.sender);
        }
    }

    function unregister() external nonReentrant {
        GameBasic.unregister(players, playersData,playersReward, state, config, nft, msg.sender);
    }

    function endGame() public nonReentrant {
        GameBasic.endGame(state, players, playersData, playersReward, nft, config);
    }

    function claimReward() external nonReentrant {
        GameBasic.claimReward(playersReward, battleToken, nft, owner(), config.tokenRewardTax, msg.sender);
    }

    // when one player is out of shrink circle, and does nothing for a while. anyone can forcibly remove the player and get eth reward
    function forceRemovePlayer(address playerAddress) external nonReentrant checkEndGame {
        require(canForceRemovePlayer(playerAddress), "Force Remove");
        GameBasic.killPlayer(players, playersData, _tokensOnGround, tilemap, GameBasic.KillParams({
            nft: nft,
            mapSeed: mapSeed,
            round: state.round,
            config: config,
            player: playerAddress
        }));
        battleToken.mint(msg.sender, uint(config.forceRemoveRewardToken) * (1 ether));
    }

    modifier checkEndGame() {
        _;
        if (state.status == GameConstants.GAME_STATUS_RUNNING && players.length == 0) {
            endGame();
        }
    }

    // modifier
    modifier checkConfig(GameConfig memory newConfig) {
        require(newConfig.mapSize % 8 == 0, "mapsize % 8 != 0");
        require(newConfig.mapSize < 256, "mapSize < 256");
        uint tileCount = (newConfig.mapSize / 8) * (newConfig.mapSize / 8);
        require(newConfig.needPlayerCount >= tileCount, "few players");
        _;
    }

    function _beforePlayerAction() internal {
        require(state.status == GameConstants.GAME_STATUS_RUNNING, "not running");
        address player = signer2player[msg.sender];
        uint playerData = playersData[player];
        require(playerData != 0, "not a player");
        require(PlayerDataHelper.getTick(playerData) < gameTick(), "Only One Action in One Tick");
        GameBasic.adjustShrinkCenter(state, config, mapSeed, player);
    }

    function _afterPlayerAction(uint damage) internal checkEndGame {
        address player = signer2player[msg.sender];
        uint playerData = playersData[player];
        if (playerData != 0) {
            uint tick = gameTick();
            playersData[player] = PlayerDataHelper.updateTick(playerData, tick);
            if (damage > 0) {
                GameBasic.applyDamage(players, playersData, _tokensOnGround, tilemap, GameBasic.ApplyDamageParams({
                    nft: nft,
                    mapSeed: mapSeed,
                    state: state,
                    config: config,
                    player: player,
                    damage: damage,
                    canDodge: false
                }));
            }

            if ((tick - state.newChestBoxLastTick) > config.chestboxGenerateIntervalTicks) {
                GameBasic.newChestBox(tilemap, state, config, mapSeed, player);
                state.newChestBoxLastTick = uint16(tick);
            }
        }
    }

    modifier playerAction() {
        _beforePlayerAction();
        uint damage = damageByShrinkCircle(signer2player[msg.sender]);
        _;
        _afterPlayerAction(damage);
    }

    function actionMove(uint[] calldata path) external playerAction {
        GameAction.move(playersData, tilemap,
            GameAction.MoveParams({
                config: config,
                round: state.round,
                mapSeed: mapSeed,
                player: signer2player[msg.sender],
                path: path
            })
        );
    }

    function actionMoveWithBoots(uint tokenIndex, uint[] calldata path) external playerAction {
        GameAction.moveWithBoots(playersData, tilemap, GameAction.BootsParams({
                config: config,
                state: state,
                nft: nft,
                mapSeed: mapSeed,
                player: signer2player[msg.sender],
                path: path,
                tokenIndex: tokenIndex
            })
        );
    }

    function actionBomb(uint tokenIndex, uint targetPos, address[] memory targets, bool[] memory targetsIsPlayer) external playerAction {
        GameAction.bomb(players, playersData, tilemap, _tokensOnGround, GameAction.BombParams({
            mapSeed: mapSeed,
            state: state,
            config: config,
            nft: nft,
            player: signer2player[msg.sender],
            tokenIndex: tokenIndex,
            bombPos: targetPos,
            targets: targets,
            targetsIsPlayer: targetsIsPlayer
        }));
    }

    function actionShoot(uint tokenIndex, address target, bool targetIsPlayer) external playerAction {
        GameAction.shoot(players, playersData, _tokensOnGround, tilemap, GameAction.ShootParams({
            nft: nft,
            mapSeed: mapSeed,
            state: state,
            config: config,
            tokenIndex: tokenIndex,
            target: target,
            targetIsPlayer: targetIsPlayer,
            player: signer2player[msg.sender]
        }));
    }

    function actionEat(uint tokenIndex) external playerAction {
        GameAction.eat(playersData, GameAction.EatParams({
            round: state.round,
            nft: nft,
            player: signer2player[msg.sender],
            tokenIndex: tokenIndex
        }));
    }

    function actionPick(uint[] calldata pos, uint[][] calldata tokensIdAndIndex) external playerAction {
        GameAction.pick(playersData, _tokensOnGround, tilemap,
            GameAction.PickParams({
                state: state,
                mapSeed: mapSeed,
                mapSize: config.mapSize,
                nft: nft,
                player: signer2player[msg.sender],
                pos: pos,
                tokensIdAndIndex: tokensIdAndIndex
            })
        );
    }

    function actionDrop(uint pos, uint[] calldata tokenIndexes) external playerAction {
        GameAction.drop(playersData, _tokensOnGround, GameAction.DropParams({
            round: state.round,
            player: signer2player[msg.sender],
            pos: pos,
            tokenIndexes: tokenIndexes
        }));
    }

    // function actionExit() external playerAction {
    //     GameBasic.exit();
    // }

    // view functions
    function playerSpawnPos(address playerAddress) public view returns(uint playerPos) {
        require(state.status == GameConstants.GAME_STATUS_RUNNING, "not running");
        return GameView.playerSpawnPos(tilemap , mapSeed, config.mapSize, playerAddress);
    }

    function allTokensOnGround(uint fromX, uint fromY, uint toX, uint toY) external view returns(uint[][] memory allTokenIds) {
        return GameView.allTokensOnGround(_tokensOnGround, state.round, fromX, fromY, toX, toY);
    }

    function playerProperty(address playerAddress) public view returns(uint keyIndex, uint pos, uint tick, uint[] memory tokenIds) {
        return PlayerDataHelper.decode(playersData[playerAddress]);
    }

    function playerCount() external view returns(uint) {
        return players.length;
    }

    function gameTick() public view returns(uint) {
        return GameView.gameTick(state.startTime, config.tickTime);
    }

    function shrinkRect() public view returns(uint left, uint top, uint right, uint bottom) {
        return GameView.shrinkRect(state, config);
    }

    function isOutOfShrinkCircle(address playerAddress) public view returns(bool) {
        return GameView.isOutOfShrinkCircle(playersData, tilemap, mapSeed, state, config, playerAddress);
    }

    function canForceRemovePlayer(address playerAddress) public view returns(bool) {
        return isOutOfShrinkCircle(playerAddress) && gameTick() - PlayerDataHelper.getTick(playersData[playerAddress]) > config.forceRemoveTicks;
    }

    function damageByShrinkCircle(address playerAddress) public view returns(uint damage) {
        return GameView.damageByShrinkCircle(playersData, tilemap, mapSeed, state, config, playerAddress);
    }

    // only for owner
    function forceEndGame() external onlyOwner {
        GameBasic.endGameState(state);

        uint totalCount = players.length;
        for(uint i = 0; i < totalCount; i++) {
            delete playersData[players[i]];
        }
        delete players;
        //burn left tokens
        GameBasic.burnAllTokens(nft);
    }

    function setConfig(GameConfig calldata newconfig) external onlyOwner checkConfig(newconfig) {
        config = newconfig;
    }

    function setPause(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Property {

    uint public constant NFT_TYPE_CHARACTER = 1;
    uint public constant NFT_TYPE_GUN = 2;
    uint public constant NFT_TYPE_BOMB = 3;
    uint public constant NFT_TYPE_ARMOR = 4;
    uint public constant NFT_TYPE_RING = 5;
    uint public constant NFT_TYPE_FOOD = 6;
    uint public constant NFT_TYPE_BOOTS = 7;

    function decodeType(uint encodeData) internal pure returns (uint) {
        uint t = encodeData >> 248;
        require(t > 0);
        return t;
    }

    function propertyCount(uint encodeData) internal pure returns (uint) {
        return encodeData & 0xffff;
    }

    // function encodeProperty(uint nftType, uint[] memory properties) internal pure returns (uint encodeData) {
    //     encodeData = (nftType << 248) | (properties.length);
    //     for(uint i = 0; i < properties.length; i++) {
    //         encodeData |= (properties[i] << (i * 16 + 16));
    //     }
    // }

    function encodeProperty1(uint nftType, uint property1) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 1;
        encodeData |= property1 << 16;
    }

    function encodeProperty2(uint nftType, uint property1, uint property2) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 2;
        encodeData |= property1 << 16;
        encodeData |= property2 << 32;
    }

    function encodeProperty3(uint nftType, uint property1, uint property2, uint property3) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 3;
        encodeData |= property1 << 16;
        encodeData |= property2 << 32;
        encodeData |= property3 << 48;
    }

    function encodeProperty4(uint nftType, uint property1, uint property2, uint property3, uint property4) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 4;
        encodeData |= property1 << 16;
        encodeData |= property2 << 32;
        encodeData |= property3 << 48;
        encodeData |= property4 << 64;
    }

    function decodeProperty1(uint encodeData) internal pure returns (uint) {
        return (encodeData >> 16) & 0xffff;
    }

    function decodeProperty2(uint encodeData) internal pure returns (uint, uint) {
        return ((encodeData >> 16) & 0xffff, (encodeData >> 32) & 0xffff);
    }

    function decodeProperty3(uint encodeData) internal pure returns (uint, uint, uint) {
        return ((encodeData >> 16) & 0xffff, (encodeData >> 32) & 0xffff, (encodeData >> 48) & 0xffff);
    }

    function decodeProperty4(uint encodeData) internal pure returns (uint, uint, uint, uint) {
        return ((encodeData >> 16) & 0xffff, (encodeData >> 32) & 0xffff, (encodeData >> 48) & 0xffff, (encodeData >> 64) & 0xffff);
    }

    /**
     * 0-16: hp
     * 16-32: max hp
     * 32-48: bag capacity
     */
    function decodeCharacterProperty(uint encodeData) internal pure returns (uint hp, uint maxHP, uint bagCapacity) {
        require(decodeType(encodeData) == NFT_TYPE_CHARACTER && propertyCount(encodeData) == 3, "not character");
        return decodeProperty3(encodeData);
    }

    function encodeCharacterProperty(uint hp, uint maxHP, uint bagCapacity) internal pure returns (uint) {
        return encodeProperty3(NFT_TYPE_CHARACTER, hp, maxHP, bagCapacity);
    }

    /**
     * 0-16: bullet count
     * 16-32: shoot range
     * 32-48: bullet damage
     * 48-64: triple damage chance
     */
    function decodeGunProperty(uint encodeData) internal pure returns (uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) {
        require(decodeType(encodeData) == NFT_TYPE_GUN && propertyCount(encodeData) == 4, "not gun");
        return decodeProperty4(encodeData);
    }

    function encodeGunProperty(uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) internal pure returns (uint) {
        return encodeProperty4(NFT_TYPE_GUN, bulletCount, shootRange, bulletDamage, tripleDamageChance);
    }

    /**
     * 0-16: throwing range
     * 16-32: explosion range
     * 32-48: damage
     */
    function decodeBombProperty(uint encodeData) internal pure returns (uint throwRange, uint explosionRange, uint damage) {
        require(decodeType(encodeData) == NFT_TYPE_BOMB && propertyCount(encodeData) == 3, "not bomb");
        return decodeProperty3(encodeData);
    }

    function encodeBombProperty(uint throwRange, uint explosionRange, uint damage) internal pure returns (uint) {
        return encodeProperty3(NFT_TYPE_BOMB, throwRange, explosionRange, damage);
    }

    /**
     * 
     * 0-16: defense
     */
    function decodeArmorProperty(uint encodeData) internal pure returns (uint defense) {
        require(decodeType(encodeData) == NFT_TYPE_ARMOR && propertyCount(encodeData) == 1, "not armor");
        return decodeProperty1(encodeData);
    }


    function encodeArmorProperty(uint defense) internal pure returns(uint) {
        return encodeProperty1(NFT_TYPE_ARMOR, defense);
    }

    /**
     * 
     * 0-16: dodgeCount
     * 16-32: dodgeChance
     */
    function decodeRingProperty(uint encodeData) internal pure returns (uint dodgeCount, uint dodgeChance) {
        require(decodeType(encodeData) == NFT_TYPE_RING && propertyCount(encodeData) == 2, "not ring");
        return decodeProperty2(encodeData);
    }

    function encodeRingProperty(uint dodgeCount, uint dodgeChance) internal pure returns(uint) {
        return encodeProperty2(NFT_TYPE_RING, dodgeCount, dodgeChance);
    }

    function decodeFoodProperty(uint encodeData) internal pure returns (uint heal) {
        require(decodeType(encodeData) == NFT_TYPE_FOOD && propertyCount(encodeData) == 1, "not food");
        return decodeProperty1(encodeData);
    }

    function encodeFoodProperty(uint heal) internal pure returns(uint) {
        return encodeProperty1(NFT_TYPE_FOOD, heal);
    }
    
    function decodeBootsProperty(uint encodeData) internal pure returns(uint usageCount, uint moveMaxSteps) {
        require(decodeType(encodeData) == NFT_TYPE_BOOTS && propertyCount(encodeData) == 2, "not boots");
        return decodeProperty2(encodeData);
    }

    function encodeBootsProperty(uint usageCount, uint moveMaxSteps) internal pure returns(uint) {
        return encodeProperty2(NFT_TYPE_BOOTS, usageCount, moveMaxSteps);
    }


    function newProperty(uint seed, uint probability) internal pure returns(uint property) {
        uint t = (probability >> (4 * (seed % 20))) & 0xf;
        seed = seed >> 8;
        property = 0;
        if (t == Property.NFT_TYPE_CHARACTER) {
            property = newCharacterProperty(seed);
        } else if (t == Property.NFT_TYPE_GUN) {
            property = newGunProperty(seed);
        } else if (t == Property.NFT_TYPE_BOMB) {
            property = newBombProperty(seed);
        } else if (t == Property.NFT_TYPE_ARMOR) {
            property = newArmorProperty(seed);
        } else if (t == Property.NFT_TYPE_RING) {
            property = newRingProperty(seed);
        } else if (t == Property.NFT_TYPE_FOOD) {
            property = newFoodProperty(seed);
        } else if (t == Property.NFT_TYPE_BOOTS) {
            property = newBootsProperty(seed);
        } else {
            revert("Unknown Type");
        }
    }

    /**
     * maxHp: 16-100(possible: 16, 20, 25, 33, 50, 100)
     * bagCapacity: 1-6(possible: 1-6)
     * maxHP * bagCapacity = 100 (volatility 30%)
     */
    function newCharacterProperty(uint seed) private pure returns (uint) {
        uint bagCapacity = seed % 6 + 1;
        uint hp = 100 * ((seed >> 4) % 60 + 70) / bagCapacity / 100;
        return encodeCharacterProperty(hp, hp, bagCapacity);
    }

    /**
     * bulletCount: 1-10: 1-10
     * shootRange: 1-16: 1-16
     * bulletDamage: 3-30: 3,7,10,15,30
     * criticalStrikeProbability: 10%-100%
     * 
     * bulletCount * (1 - 1/(shootRange/4+1)) * bulletDamage = 30 (volatility 30%)
     * bulletCount * criticalStrikeProbability = 100%
     */
    function newGunProperty(uint seed) private pure returns (uint) {
        uint bulletCount = seed % 10 + 1;
        uint shootRange = (seed >> 4) % 16 + 1;
        uint bulletDamage = 30 * ((seed >> 8) % 60 + 70) / bulletCount / (100 - 100/(shootRange/4+2));
        uint tripleDamageChance = 100 / bulletCount;
        return encodeGunProperty(bulletCount, shootRange, bulletDamage, tripleDamageChance);
    }

    /**
     * throwRange: 5-16
     * explosionRange: 1-10
     * damage: 10-100: 10, 11, 12, 14, 16, 20, 25, 33, 50, 100
     * 
     * explosionRange * damage = 100 (volatility 30%)
     */
    function newBombProperty(uint seed) private pure returns (uint) {
        uint throwRange = seed % 12 + 5;
        uint explosionRange = (seed >> 4) % 10 + 1;
        uint damage = 100 * ((seed >> 8) % 60 + 70) / explosionRange / 100;
        return encodeBombProperty(throwRange, explosionRange, damage);
    }

    /**
     * defense: 20-100
     */
    function newArmorProperty(uint seed) private pure returns (uint) {
        uint defense = seed % 80 + 20;
        return encodeArmorProperty(defense);
    }

    /**
     * dodgeCount: 3-6
     * dodgeChance: 50-100
     * 
     * dodgeChance * dodgeCount = 300 (volatility 30%)
     */
    function newRingProperty(uint seed) private pure returns (uint) {
        uint dodgeCount = seed % 4 + 3;
        uint dodgeChance = 300 * ((seed >> 8) % 60 + 70) / dodgeCount / 100;
        dodgeChance = dodgeChance > 100 ? 100 : dodgeChance;
        return encodeRingProperty(dodgeCount, dodgeChance);
    }

    /**
     * heal: 20-100
     */
    function newFoodProperty(uint seed) private pure returns (uint) {
        uint heal = seed % 80 + 20;
        return encodeFoodProperty(heal);
    }

    /**
     * usageCount: 1-3
     * moveMaxSteps: 5-15: 5, 10, 15
     * 
     * usageCount * moveMaxSteps = 15 (volatility 30%)
     */
    function newBootsProperty(uint seed) private pure returns (uint) {
        uint usageCount = seed % 3 + 1;
        uint moveMaxSteps = 15 * ((seed >> 8) % 60 + 70) / usageCount / 100;
        return encodeBootsProperty(usageCount, moveMaxSteps);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT


library PlayerDataHelper {

    // 2^16 - 1
    uint constant MAX_POS = 65535;

    /**
     * 0-8: keyIndex
     * 8-24: pos
     * 24-44: game tick
     * 44-48: token count
     * 48-248: tokenIds, max 10 tokenIds, 20 bits for one token, hope tokenId will not exceed 2^20
     */
    function encode(uint keyIndex, uint pos, uint gameTick, uint[] memory tokenIds) internal pure returns(uint r) {
        require(tokenIds.length <= 10, "No more than 10 tokenIds");
        require(keyIndex > 0, "keyIndex = 0");
        r |= keyIndex;
        r |= (pos << 8);
        r |= (gameTick << 24);
        r |= (tokenIds.length << 44);
        for (uint i = 0; i < tokenIds.length; i++) {
            r |= (tokenIds[i] << (48 + i * 20));
        }
    }

    function decode(uint encodeData) internal pure returns(uint keyIndex, uint pos, uint tick, uint[] memory tokenIds) {
        require(encodeData != 0, "No Player");
        keyIndex = encodeData & 0xff;
        pos = (encodeData >> 8) & 0xffff;
        tick = (encodeData >> 24) & 0xfffff;
        tokenIds = getTokenIds(encodeData);
    }

    function getTokenIds(uint encodeData) internal pure returns(uint[] memory tokenIds) {
        uint tokenCount = (encodeData >> 44) & 0xf;
        tokenIds = new uint[](tokenCount);
        for(uint i = 0; i < tokenCount; i++) {
            tokenIds[i] = (encodeData >> (48 + i * 20)) & 1048575;
        }
    }

    function firstTokenId(uint encodeData) internal pure returns(uint tokenId) {
        require(encodeData != 0, "No Player");
        return (encodeData >> 48) & 1048575;
    }

    function getPos(uint encodeData) internal pure returns(uint pos) {
        require(encodeData != 0, "No Player");
        pos = (encodeData >> 8) & 0xffff;
    }

    function getTokenCount(uint encodeData) internal pure returns(uint count) {
        require(encodeData != 0, "No Player");
        count = (encodeData >> 44) & 0xf;
    }

    function getTick(uint encodeData) internal pure returns(uint tick) {
        require(encodeData != 0, "No Player");
        tick = (encodeData >> 24) & 0xfffff;
    }

    function updateTick(uint encodeData, uint tick) internal pure returns(uint) {
        return (tick << 24) | (encodeData & (~uint(0xfffff << 24)));
    }

    function updatePos(uint encodeData, uint pos) internal pure returns(uint) {
        return (pos << 8) | (encodeData & (~uint(0xffff<<8)));
    }

    function getKeyIndex(uint encodeData) internal pure returns(uint) {
        require(encodeData != 0, "No Player");
        return encodeData & 0xff;
    }

    function updateKeyIndex(uint encodeData, uint keyIndex) internal pure returns(uint) {
        return keyIndex | (encodeData & (~uint(0xff)));
    }

    function removeTokenAt(uint encodeData, uint index) internal pure returns(uint) {
        uint part1 = encodeData & 0xfffffffffff;
        uint tokenCount = (encodeData >> 44) & 0xf;
        require(index < tokenCount, "RT");
        uint tokens = encodeData >> 48;
        uint newtokens = (tokens & ((1 << (index * 20)) - 1)) | ((tokens >> 20) & (type(uint).max << (index * 20)));
        return part1 | ((tokenCount - 1) << 44) | (newtokens << 48);
    }

    function addToken(uint encodeData, uint tokenId, uint bagCapacity) internal pure returns(uint) {
        uint tokenCount = (encodeData >> 44) & 0xf;
        require(tokenCount < 10 && tokenCount < bagCapacity + 1, "AT");
        return (((encodeData & ~uint(0xf << 44)) | ((tokenCount + 1) << 44)) & ~uint(0xfffff << (48 + tokenCount * 20))) | (tokenId << (48 + tokenCount * 20));
    }
}

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./PlayerDataHelper.sol";
import "./TokenOnGroundHelper.sol";
import "./Map.sol";
import "./GameConstants.sol";
import "./GameView.sol";
import "../IBattleRoyaleGameV1.sol";
import "../IBattleRoyaleNFT.sol";
import "../BATTLE.sol";
import "./Property.sol";
import "./Utils.sol";

library GameBasic {
    
    event RegisterGame(uint indexed round, address indexed player, bool indexed isRegister, uint[] tokenIds);
    event ActionMove(uint indexed round, address indexed player, uint startPos, uint[] path);
    event ActionShoot(uint indexed round, address indexed player, uint fromPos, uint targetPos, bool hitSucceed);
    event ActionPick(uint indexed round, address indexed player);
    event ActionDrop(uint indexed round, address indexed player);
    event ActionBomb(uint indexed round, address indexed player, uint fromPos, uint targetPos, uint explosionRange);
    event ActionEat(uint indexed round, address indexed player, uint heal);

    event ActionDefend(uint indexed round, address indexed player, uint defense);
    event ActionDodge(uint indexed round, address indexed player, bool succeed);

    event PlayerHurt(uint indexed round, address indexed player, uint damage);
    event PlayerKilled(uint indexed round, address indexed player);
    event PlayerWin(uint indexed round, address indexed player, uint tokenReward, uint nftReward);

    event TileChanged(uint indexed round, uint pos);

    event TokensOnGroundChanged(uint indexed round, uint pos);

    event GameStateChanged();

    struct RegisterParams {
        IBattleRoyaleNFT nft;
        uint[] tokenIds;
        IBattleRoyaleGameV1.GameConfig config;
        uint mapSeed;
        address player;
    }

    function register(
        address[] storage players, 
        mapping(address => uint) storage playersData,
        mapping(address => uint) storage playersReward, 
        mapping(uint => uint) storage tokensOnGround, 
        mapping(uint => uint) storage tilemap, 
        IBattleRoyaleGameV1.GameState storage state, 
        RegisterParams memory p
    ) external {
        _register(players, playersData, p.nft, state.status, p.config.needPlayerCount, p.tokenIds, p.player);
        _generateMap(tokensOnGround, tilemap, state,p.nft, p.config.mapSize, p.mapSeed);
        playersReward[p.player] = Utils.addReward(playersReward[p.player], p.config.playerRewardToken, 0);
        emit RegisterGame(state.round, p.player, true, p.tokenIds);
    }

    function _register(
        address[] storage players, 
        mapping(address => uint) storage playersData, 
        IBattleRoyaleNFT nft, 
        uint8 gameStatus, 
        uint needPlayerCount, 
        uint[] memory tokenIds, 
        address player
    ) private {
        require(gameStatus == 0, "wrong status");
        require(players.length < needPlayerCount, "too many players");
        require(playersData[player] == 0, "registered");
        require(tokenIds.length > 0, "no tokens");
        require(nft.tokenType(tokenIds[0]) == Property.NFT_TYPE_CHARACTER, "first token must be a character");

        (uint hp,,uint bagCapacity) = Property.decodeCharacterProperty(nft.tokenProperty(tokenIds[0]));
        require(bagCapacity >= tokenIds.length-1, "small bag capacity");
        require(hp > 0, "died");

        uint len = tokenIds.length;
        for (uint i = 0; i < len; i++) {
            require(i == 0 || nft.tokenType(tokenIds[i]) != Property.NFT_TYPE_CHARACTER, "only one character");
            nft.transferFrom(player, address(this), tokenIds[i]);
        }
        players.push(player);
        playersData[player] = PlayerDataHelper.encode(players.length, PlayerDataHelper.MAX_POS, 0, tokenIds);
    }

    function _generateMap(
        mapping(uint => uint) storage tokensOnGround, 
        mapping(uint => uint) storage tilemap,
        IBattleRoyaleGameV1.GameState storage state,
        IBattleRoyaleNFT nft,
        uint mapSize, 
        uint mapSeed
    ) private {
        // address[] memory
        uint tileSize = mapSize / 8;
        uint tilePos = state.initedTileCount;
        if(tilePos < tileSize * tileSize) {
            uint curMap = Map.genTile(mapSeed, tilePos, mapSize);
            tilemap[tilePos] = curMap;
            state.initedTileCount = uint16(tilePos + 1);
            _dropRandomEquipments(tokensOnGround, DropRandomParams({
                nft: nft,
                mapSeed: mapSeed,
                round: state.round,
                tilePos: tilePos,
                curMap: curMap,
                mapSize: mapSize
            }));
        }
    }

    function unregister(
        address[] storage players,
        mapping(address => uint) storage playersData,
        mapping(address => uint) storage playersReward, 
        IBattleRoyaleGameV1.GameState memory state, 
        IBattleRoyaleGameV1.GameConfig memory config, 
        IBattleRoyaleNFT nft, 
        address player
    ) external {
        require(state.status == GameConstants.GAME_STATUS_REGISTER, "wrong status");
        (uint tokenReward, uint nftReward) = Utils.decodeReward(playersReward[player]);
        require(tokenReward >= config.playerRewardToken, "Reward Claimed!");
        playersReward[player] = Utils.encodeReward(tokenReward - config.playerRewardToken, nftReward);
        (,,,uint[] memory tokenIds) = PlayerDataHelper.decode(playersData[player]);
        // send back tokens
        for(uint i = 0; i < tokenIds.length; i++) {
            nft.transferFrom(address(this), player, tokenIds[i]);
        }
        _removePlayer(players, playersData, player);
        emit RegisterGame(state.round, player, false, tokenIds);
    }


    function claimReward(mapping(address => uint) storage playersReward, BATTLE battleToken, IBattleRoyaleNFT nft, address owner, uint tax, address player) external {
        (uint tokenReward, uint nftReward) = Utils.decodeReward(playersReward[player]);
        playersReward[player] = 0;
        require(tokenReward > 0 || nftReward > 0, "No Reward");
        if (tokenReward > 0) {
            battleToken.mint(player, tokenReward * (1 ether));
            uint rewardToDev = tokenReward * (1 ether) * tax / 100;
            if (rewardToDev > 0 && owner != address(0)) {
                battleToken.mint(owner, rewardToDev);
            }
        }

        for(uint i = 0; i < nftReward; i++) {
            _mint(player, nft, 0x77665544332222211111);
        }
    }

    function startGame(uint mapSeed, IBattleRoyaleGameV1.GameState memory state, uint mapSize, address player) internal returns(uint, IBattleRoyaleGameV1.GameState memory) {
        mapSeed = uint(keccak256(abi.encodePacked(mapSeed, block.timestamp, player)));
        IBattleRoyaleGameV1.GameState memory tempState = state;
        tempState.startTime = uint40(block.timestamp);
        tempState.newChestBoxLastTick = 0;

        tempState.shrinkLeft = 0;
        tempState.shrinkRight = 0;
        tempState.shrinkTop = 0;
        tempState.shrinkBottom = 0;
        tempState.status = 1;

        tempState.shrinkCenterX = uint8(mapSeed % mapSize);
        tempState.shrinkCenterY = uint8((mapSeed >> 8) % mapSize);

        tempState.shrinkTick = 1;
        emit GameStateChanged();
        return (mapSeed, tempState);
    }

    function endGame(
        IBattleRoyaleGameV1.GameState storage state, 
        address[] storage players, 
        mapping(address => uint) storage playersData, 
        mapping(address => uint) storage playersReward, 
        IBattleRoyaleNFT nft, 
        IBattleRoyaleGameV1.GameConfig memory config
    ) external {
        uint leftPlayerCount = players.length;
        require(state.status == GameConstants.GAME_STATUS_RUNNING && leftPlayerCount <= 1, "EndGame");
        endGameState(state);
        if (leftPlayerCount == 1) {
            address winerAddr = players[0];
            (,,,uint[] memory tokenIds) = PlayerDataHelper.decode(playersData[winerAddr]);
            _removePlayer(players, playersData, winerAddr);
            // send back tokens
            for(uint i = 0; i < tokenIds.length; i++) {
                nft.transferFrom(address(this), winerAddr, tokenIds[i]);
            }
            playersReward[winerAddr] = Utils.addReward(playersReward[winerAddr], config.winnerRewardToken, config.winnerRewardNFT);
            emit PlayerWin(state.round, winerAddr, config.winnerRewardToken, config.winnerRewardNFT);
        }
        //burn left tokens
        burnAllTokens(nft);
        emit GameStateChanged();
    }

    struct DropRandomParams {
        IBattleRoyaleNFT nft;
        uint mapSeed;
        uint round;
        uint tilePos;
        uint curMap;
        uint mapSize;
    }

    function _dropRandomEquipments(mapping(uint => uint) storage tokensOnGround, DropRandomParams memory p) private { 
        uint seed = uint(keccak256(abi.encodePacked(p.mapSeed, bytes("equipment"), p.tilePos)));

        uint count = seed % 3 + 3;
        uint x1 = p.tilePos % (p.mapSize / 8) * 8;
        uint y1 = p.tilePos / (p.mapSize / 8) * 8;

        for (uint i = 0; i < count; i++) {
            uint pos = (seed >> (8 + (i * 6))) % 64;
            if (Map.isEmptyTile(p.curMap, pos)) {
                /**
                 * Gun: 30%
                 * Bomb: 15%
                 * Armor: 15%
                 * Ring: 15%
                 * Food: 15%
                 * Boots: 10%
                 */
                pos = (x1 + (pos % 8)) + ((y1 + (pos / 8)) << 8);
                tokensOnGround[pos] = TokenOnGroundHelper.addToken(tokensOnGround[pos], p.round, _mint(address(this), p.nft, 0x77666555444333222222));
            }
        }
    }

    function _mint(address to, IBattleRoyaleNFT nft, uint probability) private returns(uint) {
        uint seed = uint(
            keccak256(abi.encodePacked(block.timestamp, address(this), nft.nextTokenId()))
        );
        return nft.mintByGame(to, Property.newProperty(seed, probability));
    }

    function _drop(mapping(uint => uint) storage tokensOnGround, uint round, uint[] memory tokenIds, uint startTokenIndex, uint pos) private {
        uint data = tokensOnGround[pos];
        for (uint i = startTokenIndex; i < tokenIds.length; i++) {
            data = TokenOnGroundHelper.addToken(data, round, tokenIds[i]);
        }
        tokensOnGround[pos] = data;
        emit TokensOnGroundChanged(round, pos);
    }
    
    function destroyTile(mapping(uint => uint) storage tilemap, mapping(uint => uint) storage tokensOnGround, uint mapSize, uint pos, uint mapSeed, uint round, uint tick, IBattleRoyaleNFT nft) internal {
        (uint x, uint y) = GameView.decodePos(pos);
        IBattleRoyaleGameV1.TileType t = GameView.getTileType(tilemap, x, y, mapSize);
        if (t == IBattleRoyaleGameV1.TileType.Wall || t == IBattleRoyaleGameV1.TileType.ChestBox) {
            _setTileType(tilemap, x, y, mapSize, IBattleRoyaleGameV1.TileType.None);
            if (t == IBattleRoyaleGameV1.TileType.ChestBox) {
                uint seed = uint(keccak256(abi.encodePacked(mapSeed, pos, tick, "chestbox")));
                uint count = seed % 4 + 1;
                for(uint i = 0; i < count; i++) {
                    tokensOnGround[pos] = TokenOnGroundHelper.addToken(tokensOnGround[pos], round, _mint(address(this), nft, 0x77766655544433332222));
                }
                emit TokensOnGroundChanged(round, pos);
            }
            emit TileChanged(round, pos);
        } else if (t != IBattleRoyaleGameV1.TileType.None) {
            revert("destroyTile");
        }
    }
    
    struct RingParams{
        uint round;
        address player;
        uint mapSeed;
        uint tick;
        IBattleRoyaleNFT nft;
    }

    function applyRing(mapping(address => uint) storage playersData,RingParams memory p) private returns(bool dodge) {
        dodge = false;
        uint playerData = playersData[p.player];
        uint[] memory tokenIds = PlayerDataHelper.getTokenIds(playerData);
        for (uint i = tokenIds.length - 1; i > 0; i--) {
            uint token = p.nft.tokenProperty(tokenIds[i]);
            if (Property.decodeType(token) == Property.NFT_TYPE_RING) {
                (uint dodgeCount, uint dodgeChance) = Property.decodeRingProperty(token);
                if(dodgeCount > 0) {
                    uint seed = uint(keccak256(abi.encodePacked(p.mapSeed, tokenIds[i], p.tick)));
                    if (seed % 100 < dodgeChance) {
                        dodge = true;
                    }
                    emit ActionDodge(p.round, p.player, dodge);
                    dodgeCount -= 1;
                    p.nft.setProperty(tokenIds[i], Property.encodeRingProperty(dodgeCount, dodgeChance));
                }
                if (dodgeCount == 0) {
                    p.nft.burn(tokenIds[i]);
                    playerData = PlayerDataHelper.removeTokenAt(playerData, i);
                }
            }

            if (dodge) {
                break;
            }
        }
        playersData[p.player] = playerData;
    }

    struct ArmorParams{
        uint round;
        address player;
        uint damage;
        IBattleRoyaleNFT nft;
    }

    function applyArmor(mapping(address => uint) storage playersData, ArmorParams memory p) private returns(uint) {
        uint playerData = playersData[p.player];
        (,,,uint[] memory tokenIds) = PlayerDataHelper.decode(playerData);
        for (uint i = tokenIds.length - 1; i > 0; i--) {
            uint token = p.nft.tokenProperty(tokenIds[i]);
            if (Property.decodeType(token) == Property.NFT_TYPE_ARMOR) {
                uint defense = Property.decodeArmorProperty(token);
                uint leftDefense = defense < p.damage ? 0 : defense - p.damage;
                p.damage -= defense - leftDefense;
                p.nft.setProperty(tokenIds[i], Property.encodeArmorProperty(leftDefense));
                if (leftDefense == 0) {
                    p.nft.burn(tokenIds[i]);
                    playerData = PlayerDataHelper.removeTokenAt(playerData, i);
                }
                emit ActionDefend(p.round, p.player, defense - leftDefense);
            }
            if (p.damage == 0) {
                break;
            }
        }
        playersData[p.player] = playerData;
        return p.damage;
    }

    struct ApplyDamageParams {
        IBattleRoyaleNFT nft;
        uint mapSeed;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleGameV1.GameConfig config;
        address player;
        uint damage;
        bool canDodge;
    }

    function applyDamage(address[] storage players, mapping(address => uint) storage playersData,mapping(uint => uint) storage tokensOnGround,mapping(uint => uint) storage tilemap, ApplyDamageParams memory p) public {
        if (p.damage == 0) return;

        uint characterId = PlayerDataHelper.firstTokenId(playersData[p.player]);
        uint tick = GameView.gameTick(p.state.startTime, p.config.tickTime);
        if (p.canDodge && applyRing(playersData, RingParams({
            round: p.state.round,
            player: p.player,
            mapSeed: p.mapSeed,
            tick: tick,
            nft: p.nft
        }))) {
            return;
        }
        p.damage = applyArmor(playersData, ArmorParams({
            round: p.state.round,
            player: p.player,
            damage: p.damage,
            nft: p.nft
        }));
        if (p.damage == 0) {
            return;
        }

        (uint hp, uint maxHP, uint bagCapacity) = Property.decodeCharacterProperty(p.nft.tokenProperty(characterId));
        hp = hp < p.damage ? 0 : hp - p.damage;
        p.nft.setProperty(characterId, Property.encodeCharacterProperty(hp, maxHP, bagCapacity));
        emit PlayerHurt(p.state.round, p.player, p.damage);
        if (hp == 0) {
            killPlayer(players, playersData, tokensOnGround, tilemap,
                KillParams({
                    nft: p.nft,
                    mapSeed: p.mapSeed,
                    round: p.state.round,
                    config: p.config,
                    player: p.player
                })
            );
        }
    }

    struct KillParams {
        IBattleRoyaleNFT nft;
        uint mapSeed;
        uint round;
        IBattleRoyaleGameV1.GameConfig config;
        address player;
    }

    function killPlayer(
        address[] storage players, 
        mapping(address => uint) storage playersData,
        mapping(uint => uint) storage tokensOnGround,
        mapping(uint => uint) storage tilemap,
        KillParams memory p
    ) public {
        uint[] memory tokenIds = PlayerDataHelper.getTokenIds(playersData[p.player]);
        p.nft.burn(tokenIds[0]);
        uint pos = GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.config.mapSize, p.player);
        _drop(tokensOnGround, p.round, tokenIds, 1, pos);
        _removePlayer(players, playersData, p.player);
        emit PlayerKilled(p.round, p.player);
    }

    function _removePlayer(address[] storage players, mapping(address => uint) storage playersData, address player) private {
        uint index = PlayerDataHelper.getKeyIndex(playersData[player]);
        uint totalPlayerCount = players.length;
        if (index != totalPlayerCount) {
            address lastPlayer = players[totalPlayerCount-1];
            players[index-1] = lastPlayer;
            playersData[lastPlayer] = PlayerDataHelper.updateKeyIndex(playersData[lastPlayer], index);
        }
        players.pop();
        delete playersData[player];
    }
    
    function endGameState(IBattleRoyaleGameV1.GameState storage state) internal {
        state.round += 1;
        state.initedTileCount = 0;
        state.status = 0;
    }

    function burnAllTokens(IBattleRoyaleNFT nft) internal {
        uint tokenCount = nft.balanceOf(address(this));
        for(uint i = tokenCount; i > 0; i--) {
            nft.burn(nft.tokenOfOwnerByIndex(address(this), i-1));
        }
    }

    function adjustShrinkCenter(IBattleRoyaleGameV1.GameState storage state, IBattleRoyaleGameV1.GameConfig memory config, uint mapSeed, address player) external {
        uint ticksInOneGame = config.ticksInOneGame;
        uint tick = GameView.gameTick(state.startTime, config.tickTime);
        if (tick < ticksInOneGame && tick - state.shrinkTick > 20) {
            (uint left, uint top, uint right, uint bottom) = GameView.shrinkRect(state, config);
            state.shrinkLeft = uint8(left);
            state.shrinkTop = uint8(top);
            state.shrinkRight = uint8(right);
            state.shrinkBottom = uint8(bottom);
            state.shrinkTick = uint16(tick);

            uint mapSize = config.mapSize;
            uint seed =  uint(keccak256(abi.encodePacked(mapSeed, bytes("shrink"), block.timestamp, player)));
            state.shrinkCenterX = uint8(seed % (mapSize - left - right) + left);
            state.shrinkCenterY = uint8((seed >> 8) % (mapSize - top - bottom) + top);
            emit GameStateChanged();
        }
    }

    function newChestBox(mapping(uint => uint) storage tilemap, IBattleRoyaleGameV1.GameState memory state, IBattleRoyaleGameV1.GameConfig memory config, uint mapSeed, address player) external {
        (uint left, uint top, uint right, uint bottom) = GameView.shrinkRect(state, config);
        uint mapSize = config.mapSize;
        if (left + right < mapSize && top + bottom < mapSize) {
            for (uint i = 0; i < 3; i++) {
                uint seed = uint(keccak256(abi.encodePacked(mapSeed, bytes("newChestBox"), block.timestamp, player, i)));
                uint x = seed % (mapSize - left - right) + left;
                uint y = (seed >> 8) % (mapSize - top - bottom) + top;
                if (GameView.getTileType(tilemap, x, y, mapSize) == IBattleRoyaleGameV1.TileType.None) {
                    _setTileType(tilemap, x, y, mapSize, IBattleRoyaleGameV1.TileType.ChestBox);
                    emit TileChanged(state.round, x + (y << 8));
                    break;
                }
            }
        }
    }

    function _setTileType(mapping(uint => uint) storage tilemap, uint x, uint y, uint mapSize, IBattleRoyaleGameV1.TileType tileType) internal {
        uint tilePos = y / 8 * (mapSize / 8) + x / 8;
        uint index = (y % 8 * 8 + x % 8) * 4;
        tilemap[tilePos] = (tilemap[tilePos] & ~(uint(0xf << index))) | (uint(tileType) << index);
    }
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT


library GameConstants {
    uint8 public constant GAME_STATUS_REGISTER = 0;
    uint8 public constant GAME_STATUS_RUNNING = 1;
}

pragma solidity >=0.8.0 <0.9.0;

pragma abicoder v2;

//SPDX-License-Identifier: MIT
import "./PlayerDataHelper.sol";
import "./TokenOnGroundHelper.sol";
import "../IBattleRoyaleGameV1.sol";

library GameView {
    function playerSpawnPos(mapping(uint => uint) storage tilemap, uint mapSeed, uint mapSize, address playerAddress) internal view returns(uint playerPos) {
        for(uint j = 0;;j++) {
            uint index = uint(keccak256(abi.encodePacked(mapSeed, playerAddress, j))) % (mapSize * mapSize);
            uint x = index % mapSize;
            uint y = index / mapSize;
            if (getTileType(tilemap, x, y, mapSize) == IBattleRoyaleGameV1.TileType.None) {
                return x + (y<<8);
            }
        }
    }

    function getPlayerPos(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, uint mapSeed, uint mapSize, address playerAddress) internal returns(uint pos) {
        uint data = playersData[playerAddress];
        pos = PlayerDataHelper.getPos(data);
        // initial position
        if (pos == PlayerDataHelper.MAX_POS) {
            pos = playerSpawnPos(tilemap, mapSeed, mapSize, playerAddress);
            playersData[playerAddress] = PlayerDataHelper.updatePos(data, pos);
        }
    }

    function getPlayerPosView(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, uint mapSeed, uint mapSize, address playerAddress) public view returns(uint pos) {
        uint data = playersData[playerAddress];
        pos = PlayerDataHelper.getPos(data);
        // initial position
        if (pos == PlayerDataHelper.MAX_POS) {
            pos = playerSpawnPos(tilemap, mapSeed, mapSize, playerAddress);
        }
    }

    function gameTick(uint startTime, uint tickTime) internal view returns(uint) {
        return (block.timestamp - startTime) / tickTime + 1;
    }

    function shrinkRect(IBattleRoyaleGameV1.GameState memory state, IBattleRoyaleGameV1.GameConfig memory config) public view returns(uint left, uint top, uint right, uint bottom) {
        uint tick = gameTick(state.startTime, config.tickTime) - state.shrinkTick;
        uint ticksInOneGame = config.ticksInOneGame + 1 - state.shrinkTick;
        uint mapSize = config.mapSize;
        left = state.shrinkLeft + tick * (state.shrinkCenterX - state.shrinkLeft) / ticksInOneGame;
        top = state.shrinkTop + tick * (state.shrinkCenterY - state.shrinkTop) / ticksInOneGame;
        right = state.shrinkRight + tick * (mapSize - 1 - state.shrinkCenterX - state.shrinkRight) / ticksInOneGame;
        bottom = state.shrinkBottom + tick * (mapSize - 1 - state.shrinkCenterY - state.shrinkBottom) / ticksInOneGame;
    }

    function isOutOfShrinkCircle(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, uint mapSeed, IBattleRoyaleGameV1.GameState memory state, IBattleRoyaleGameV1.GameConfig memory config, address playerAddress) public view returns(bool) {
        (uint left, uint top, uint right, uint bottom) = shrinkRect(state, config);
        uint mapSize = config.mapSize;
        uint pos = getPlayerPosView(playersData, tilemap, mapSeed, config.mapSize, playerAddress);
        (uint x, uint y) = decodePos(pos);
        return x < left || x + right >= mapSize || y < top || y + bottom >= mapSize;
    }

    function damageByShrinkCircle(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, uint mapSeed, IBattleRoyaleGameV1.GameState memory state, IBattleRoyaleGameV1.GameConfig memory config, address playerAddress) public view returns(uint damage) {
        if (isOutOfShrinkCircle(playersData, tilemap, mapSeed, state, config, playerAddress)) {
            uint currentTick = gameTick(state.startTime, config.tickTime);
            uint tick = currentTick - PlayerDataHelper.getTick(playersData[playerAddress]);
            return 5 + tick + 10 * currentTick / config.ticksInOneGame;
        }
        return 0;
    }

    function getTileType(mapping(uint => uint) storage tilemap, uint x, uint y, uint mapSize) internal view returns(IBattleRoyaleGameV1.TileType) {
        uint tile = tilemap[ y / 8 * (mapSize / 8) + x / 8];
        return IBattleRoyaleGameV1.TileType((tile >> ((y % 8 * 8 + x % 8) * 4)) & 0xf);
    }

    function allTokensOnGround(mapping(uint => uint) storage tokensOnGround, uint round, uint fromX, uint fromY, uint toX, uint toY) internal view returns(uint[][] memory allTokenIds) {
        allTokenIds = new uint[][]((toX - fromX) * (toY - fromY));
        uint i = 0;
        for (uint y = fromY; y < toY; y++) {
            for (uint x = fromX; x < toX; x++) {
                allTokenIds[i] = TokenOnGroundHelper.tokens(tokensOnGround[x + (y << 8)], round);
                i += 1;
            }
        }
    }

    function decodePos(uint pos) internal pure returns(uint x, uint y) {
        x = pos & 0xff;
        y = (pos >> 8) & 0xff;
    }
}

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
//SPDX-License-Identifier: MIT
import "./PlayerDataHelper.sol";
import "./TokenOnGroundHelper.sol";
import "./GameConstants.sol";
import "./GameView.sol";
import "./GameBasic.sol";
import "./Utils.sol";
import "../IBattleRoyaleGameV1.sol";
import "../IBattleRoyaleNFT.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

//import "hardhat/console.sol";

library GameAction {
    using SignedMath for int;

    event RegisterGame(uint indexed round, address indexed player, bool indexed isRegister, uint[] tokenIds);
    event ActionMove(uint indexed round, address indexed player, uint startPos, uint[] path);
    event ActionShoot(uint indexed round, address indexed player, uint fromPos, uint targetPos, bool hitSucceed);
    event ActionPick(uint indexed round, address indexed player);
    event ActionDrop(uint indexed round, address indexed player);
    event ActionBomb(uint indexed round, address indexed player, uint fromPos, uint targetPos, uint explosionRange);
    event ActionEat(uint indexed round, address indexed player, uint heal);

    event ActionDefend(uint indexed round, address indexed player, uint defense);
    event ActionDodge(uint indexed round, address indexed player, bool succeed);

    event PlayerHurt(uint indexed round, address indexed player, uint damage);
    event PlayerKilled(uint indexed round, address indexed player);
    event PlayerWin(uint indexed round, address indexed player, uint tokenReward, uint nftReward);

    event TileChanged(uint indexed round, uint pos);

    event TokensOnGroundChanged(uint indexed round, uint pos);

    event GameStateChanged();

    function _move(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, MoveParams memory p) private {
        uint mapSize = p.config.mapSize;
        uint pos = GameView.getPlayerPos(playersData, tilemap, p.mapSeed, mapSize, p.player);
        (uint x, uint y) = GameView.decodePos(pos);
        for (uint i = 0; i < p.path.length; i++) {
            uint dir = p.path[i];
            // left
            if (dir == 0) {
                require(x > 0);
                x -= 1;
            }
            // up
            else if (dir == 1) {
                require(y > 0);
                y -= 1;
            }
            // right
            else if (dir == 2) {
                require(x < mapSize - 1);
                x += 1;
            }
            // down
            else if (dir == 3) {
                require(y < mapSize - 1);
                y += 1;
            } else {
                revert();
            }
            require(GameView.getTileType(tilemap, x, y, mapSize) == IBattleRoyaleGameV1.TileType.None);
        }
        playersData[p.player] = PlayerDataHelper.updatePos(playersData[p.player], x + (y << 8));
        emit ActionMove(p.round, p.player, pos, p.path);
    }

    struct MoveParams {
        IBattleRoyaleGameV1.GameConfig config;
        uint round;
        uint mapSeed;
        address player;
        uint[] path;
    }
    
    function move(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, MoveParams memory p) external {
        require(p.path.length > 0 && p.path.length <= p.config.moveMaxSteps);
        _move(playersData, tilemap, p);
    }

    struct BootsParams {
        IBattleRoyaleGameV1.GameConfig config;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleNFT nft;

        uint mapSeed;
        address player;
        uint[] path;
        uint tokenIndex;
    }

    function moveWithBoots(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, BootsParams memory p) external {
        uint bootsId = _getTokenId(playersData[p.player], p.tokenIndex);
        (uint usageCount, uint moveMaxSteps) = Property.decodeBootsProperty(p.nft.tokenProperty(bootsId));
        require(usageCount > 0, "Boots1");
        require(p.path.length > 0 && p.path.length <= p.config.moveMaxSteps + moveMaxSteps);
        _move(playersData, tilemap, MoveParams({
            config: p.config,
            round: p.state.round,
            mapSeed: p.mapSeed,
            player: p.player,
            path: p.path
        }));

        p.nft.setProperty(bootsId, Property.encodeBootsProperty(usageCount - 1, moveMaxSteps));
        if (usageCount == 1) {
            p.nft.burn(bootsId);
            playersData[p.player] = PlayerDataHelper.removeTokenAt(playersData[p.player], p.tokenIndex);
        }
    }

    struct LinePathParams {
        int x0;
        int y0;
        int x1;
        int y1;

        int dx;
        int dy;
        int err;
        int ystep;
        bool steep;
    }

    function _getXY(int fromPos, int toPos) private pure returns(LinePathParams memory) {
        int x0 = fromPos & 0xff;
        int y0 = (fromPos >> 8) & 0xff;
        int x1 = toPos & 0xff;
        int y1 = (toPos >> 8) & 0xff;

        bool steep = (y1 - y0).abs() > (x1-x0).abs();

        if (steep) {
            (x0, y0) = (y0, x0);
            (x1, y1) = (y1, x1);
        }
        if (x0 > x1) {
            (x0, x1) = (x1, x0);
            (y0, y1) = (y1, y0);
        }
        return LinePathParams({
            x0: x0,
            y0: y0,
            x1: x1,
            y1: y1,
            dx: x1 - x0,
            dy: int((y1 - y0).abs()),
            err: (x1 - x0) / 2,
            ystep: y0 < y1 ? int(1) : int(-1),
            steep: steep
        });
    }
    
    // Bresenham's line algorithm
    function _checkPathForShoot(mapping(uint => uint) storage tilemap, uint mapSize, int fromPos, int toPos, int excludePos) private view {
        LinePathParams memory p = _getXY(fromPos, toPos);
        int y = p.y0;
        for(int x = p.x0; x <= p.x1; x++) {
            IBattleRoyaleGameV1.TileType t = p.steep ? GameView.getTileType(tilemap, uint(y), uint(x), mapSize) : GameView.getTileType(tilemap, uint(x), uint(y), mapSize);
            require((p.steep ? (x << 8) + y : (y << 8) + x) == excludePos || t == IBattleRoyaleGameV1.TileType.None || t == IBattleRoyaleGameV1.TileType.Water);
            p.err -= p.dy;
            if (p.err < 0) {
                y += p.ystep;
                p.err += p.dx;
            }
        }
    }

    function _getTokenId(uint playerData, uint tokenIndex) private pure returns(uint) {
        (,,,uint[] memory tokenIds) = PlayerDataHelper.decode(playerData);
        require(tokenIndex < tokenIds.length);
        return tokenIds[tokenIndex];
    }

    struct ShootParams2 {
        uint fromPos;
        uint toPos;
        address player;
        address target;
        bool targetIsPlayer;
        uint shootRange;
        uint shootDamage;
        uint criticalStrikeProbability;
        uint tokenId;
        IBattleRoyaleNFT nft;
        uint mapSeed;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleGameV1.GameConfig config;
    }

    function _calcDamage(ShootParams2 memory p) private view returns(uint) {
        uint distance = Math.sqrt(Utils.distanceSquare(p.fromPos, p.toPos) * 10000);
        uint missChance = (Math.max(distance, 100) - 100) / p.shootRange;
        if (missChance >= 100) {
            return 0;
        }
        uint seed = uint(keccak256(abi.encodePacked(p.mapSeed, p.player, p.tokenId, GameView.gameTick(p.state.startTime, p.config.tickTime))));
        if(seed % 100 < missChance) {
            return 0;
        }
        bool criticalStrike = (seed >> 8) % 100 < p.criticalStrikeProbability;
        return p.shootDamage * (criticalStrike ? 3 : 1);
    }

    function _shoot(
        address[] storage players, 
        mapping(address => uint) storage playersData,
        mapping(uint => uint) storage tokensOnGround,
        mapping(uint => uint) storage tilemap, 
        ShootParams2 memory p
    ) private {
        uint damage = _calcDamage(p);
        emit ActionShoot(p.state.round, p.player, p.fromPos, p.toPos, damage > 0);
        if (damage > 0) {
            if (p.targetIsPlayer) {
                GameBasic.applyDamage(players, playersData, tokensOnGround, tilemap, GameBasic.ApplyDamageParams({
                    nft: p.nft,
                    mapSeed: p.mapSeed,
                    state: p.state,
                    config: p.config,
                    player: p.target,
                    damage: damage,
                    canDodge: true
                }));
            } else {
                GameBasic.destroyTile(tilemap, tokensOnGround, p.config.mapSize, p.toPos, p.mapSeed,p.state.round, GameView.gameTick(p.state.startTime, p.config.tickTime), p.nft);
            }
        }
    }

    struct ShootParams {
        IBattleRoyaleNFT nft;
        uint mapSeed;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleGameV1.GameConfig config;

        address player;

        uint tokenIndex;
        address target;
        bool targetIsPlayer;
    }

    function shoot(
        address[] storage players, 
        mapping(address => uint) storage playersData, 
        mapping(uint => uint) storage tokensOnGround, 
        mapping(uint => uint) storage tilemap, 
        ShootParams memory p
    ) external {
        uint gunId = _getTokenId(playersData[p.player], p.tokenIndex);
        (uint bulletCount, uint shootRange, uint bulletDamage, uint criticalStrikeProbability) = Property.decodeGunProperty(p.nft.tokenProperty(gunId));
        require(bulletCount > 0, "No Bullet");
        uint fromPos = GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.config.mapSize, p.player);
        uint toPos = p.targetIsPlayer ? GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.config.mapSize, p.target) : uint256(uint160(p.target));
        _checkPathForShoot(tilemap, p.config.mapSize, int(fromPos), int(toPos), p.targetIsPlayer ? int(PlayerDataHelper.MAX_POS) : int(toPos));

        _shoot(
            players, playersData, tokensOnGround, tilemap,
            ShootParams2({
            fromPos: fromPos,
            toPos: toPos,
            target: p.target,
            targetIsPlayer: p.targetIsPlayer,
            shootRange: shootRange,
            shootDamage: bulletDamage,
            criticalStrikeProbability: criticalStrikeProbability,
            tokenId: gunId,
            nft: p.nft,
            mapSeed: p.mapSeed,
            player: p.player,
            state: p.state,
            config: p.config
        }));
        p.nft.setProperty(gunId, Property.encodeGunProperty(bulletCount - 1, shootRange, bulletDamage, criticalStrikeProbability));
        if (bulletCount == 1) {
            p.nft.burn(gunId);
            playersData[p.player] = PlayerDataHelper.removeTokenAt(playersData[p.player], p.tokenIndex);
        }
    }

    struct PickParams2 {
        int playerX;
        int playerY;
        uint bagCapacity;
        uint round;
        uint posLength;
        uint playerData;
    }

    function _pickOne(mapping(uint => uint) storage tokensOnGround, PickParams2 memory p, uint pos, uint[] memory tokensIdAndIndex) private {
        uint groundTokens = tokensOnGround[pos];
        uint[] memory tokens = TokenOnGroundHelper.tokens(groundTokens, p.round);
        require(tokensIdAndIndex.length % 2 == 0, "Pick3");
        uint j = 0;
        for (j = 0; j < tokensIdAndIndex.length; j += 2) {
            require(tokensIdAndIndex[j] == tokens[tokensIdAndIndex[j+1]], "Pick4");
            require(j + 3 >= tokensIdAndIndex.length || tokensIdAndIndex[j+1] > tokensIdAndIndex[j+3], "Pick5");
            p.playerData = PlayerDataHelper.addToken(p.playerData, tokensIdAndIndex[j], p.bagCapacity);
            groundTokens = TokenOnGroundHelper.removeToken(groundTokens, p.round, tokensIdAndIndex[j+1]);
        }
        tokensOnGround[pos] = groundTokens;
        emit TokensOnGroundChanged(p.round, pos);
    }

    struct PickParams {
        IBattleRoyaleGameV1.GameState state;
        uint mapSeed; 
        uint mapSize;
        IBattleRoyaleNFT nft;
        address player;
        uint[] pos;
        uint[][] tokensIdAndIndex;
    }

    function pick(
        mapping(address => uint) storage playersData,
        mapping(uint => uint) storage tokensOnGround, 
        mapping(uint => uint) storage tilemap, 
        PickParams memory p
    ) external {
        require(p.pos.length == p.tokensIdAndIndex.length, "Pick1");

        uint playerData = playersData[p.player];
        uint playerPos = GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.mapSize, p.player);

        PickParams2 memory p2 = PickParams2({
            playerX: int(playerPos & 0xff),
            playerY: int(playerPos >> 8),
            bagCapacity: 0,
            round: p.state.round,
            posLength: p.pos.length,
            playerData: playerData
        });
        (,,p2.bagCapacity) = Property.decodeCharacterProperty(p.nft.tokenProperty(PlayerDataHelper.firstTokenId(playerData)));
        for (uint i = 0; i < p2.posLength; i++) {
            require((int(p.pos[i] & 0xff) - p2.playerX).abs() + (int(p.pos[i] >> 8) - p2.playerY).abs() <= 1, "Pick2");
            _pickOne(tokensOnGround, p2, p.pos[i], p.tokensIdAndIndex[i]);
        }
        playersData[p.player] = p2.playerData;
        emit ActionPick(p.state.round, p.player);
    }

    struct DropParams {
        uint round;
        address player;
        uint pos;
        uint[] tokenIndexes;
    }

    function drop(mapping(address => uint) storage playersData,mapping(uint => uint) storage tokensOnGround, DropParams memory p) external {
        uint playerData = playersData[p.player];
        (,uint playerPos,, uint[] memory tokenIds) = PlayerDataHelper.decode(playerData);
        require((int(p.pos & 0xff) - int(playerPos & 0xff)).abs() + (int(p.pos >> 8) - int(playerPos >> 8)).abs() <= 1, "Drop");
        uint data = tokensOnGround[p.pos];
        uint round = p.round;
        for (uint i = p.tokenIndexes.length; i > 0; i--) {
            if (i > 1) {
                require(p.tokenIndexes[i-2] < p.tokenIndexes[i-1], "Drop");
            }
            playerData = PlayerDataHelper.removeTokenAt(playerData, p.tokenIndexes[i-1]);
            data = TokenOnGroundHelper.addToken(data, round, tokenIds[p.tokenIndexes[i-1]]);
        }
        playersData[p.player] = playerData;
        emit ActionDrop(p.round, p.player);
        tokensOnGround[p.pos] = data;
        emit TokensOnGroundChanged(p.round, p.pos);
    }

    struct BombParams2 {
        uint mapSeed;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleGameV1.GameConfig config;

        uint bombPos;

        uint throwRange;
        uint explosionRange;
        uint damage;

        address target;
        bool targetIsPlayer;
        IBattleRoyaleNFT nft;
    }

    function _checkBombOne(mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, BombParams2 memory p) private {
        uint pos = p.targetIsPlayer ? GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.config.mapSize, p.target): uint(uint160(p.target));
        uint distance = Utils.distanceSquare(pos, p.bombPos);
        require(distance <= p.explosionRange * p.explosionRange, "Bomb");
        _checkPathForShoot(tilemap, p.config.mapSize, int(p.bombPos), int(pos), int(pos));
    }

    function _bombOne(address[] storage players, mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, mapping(uint => uint) storage tokensOnGround, BombParams2 memory p) private {
        if (p.targetIsPlayer) {
            uint pos = PlayerDataHelper.getPos(playersData[p.target]);
            uint distance = Utils.distanceSquare(pos, p.bombPos);
            uint damage = p.damage * (100 - Math.sqrt(distance * 10000) / (p.explosionRange + 1)) / 100;
            GameBasic.applyDamage(players, playersData, tokensOnGround, tilemap,
                GameBasic.ApplyDamageParams({
                    nft: p.nft,
                    mapSeed: p.mapSeed,
                    state: p.state,
                    config: p.config,
                    player: p.target,
                    damage: damage,
                    canDodge: false
                })
            );
        } else {
            GameBasic.destroyTile(tilemap, tokensOnGround, p.config.mapSize, uint(uint160(p.target)), p.mapSeed, p.state.round, GameView.gameTick(p.state.startTime, p.config.tickTime), p.nft);
        }
    }

    struct BombParams {
        uint mapSeed;
        IBattleRoyaleGameV1.GameState state;
        IBattleRoyaleGameV1.GameConfig config;

        IBattleRoyaleNFT nft;
        address player;

        uint tokenIndex;
        uint bombPos;
        address[] targets;
        bool[] targetsIsPlayer;
    }

    function bomb(address[] storage players, mapping(address => uint) storage playersData, mapping(uint => uint) storage tilemap, mapping(uint => uint) storage tokensOnGround,BombParams memory p) external {
        uint bombId = _getTokenId(playersData[p.player], p.tokenIndex);
        (uint throwRange, uint explosionRange, uint damage) = Property.decodeBombProperty(p.nft.tokenProperty(bombId));
        uint playerPos = GameView.getPlayerPos(playersData, tilemap, p.mapSeed, p.config.mapSize, p.player);
        require(Utils.distanceSquare(playerPos, p.bombPos) <= throwRange * throwRange, "Bomb1");
        require(p.targets.length == p.targetsIsPlayer.length, "Bomb2");
        require(GameView.getTileType(tilemap, p.bombPos & 0xff, p.bombPos >> 8, p.config.mapSize) == IBattleRoyaleGameV1.TileType.None, "Bomb3");

        for(uint i = 0; i < p.targets.length; i++) {
            _checkBombOne(playersData, tilemap, BombParams2({
                throwRange: throwRange,
                explosionRange: explosionRange,
                damage: damage,
                bombPos: p.bombPos,
                target: p.targets[i],
                targetIsPlayer: p.targetsIsPlayer[i],
                nft: p.nft,
                mapSeed: p.mapSeed,
                state: p.state,
                config: p.config
            }));
        }

        for(uint i = 0; i < p.targets.length; i++) {
            _bombOne(players, playersData, tilemap, tokensOnGround, BombParams2({
                throwRange: throwRange,
                explosionRange: explosionRange,
                damage: damage,
                bombPos: p.bombPos,
                target: p.targets[i],
                targetIsPlayer: p.targetsIsPlayer[i],
                nft: p.nft,
                mapSeed: p.mapSeed,
                state: p.state,
                config: p.config
            }));
        }
        p.nft.burn(bombId);
        playersData[p.player] = PlayerDataHelper.removeTokenAt(playersData[p.player], p.tokenIndex);

        emit ActionBomb(p.state.round, p.player, playerPos, p.bombPos, explosionRange);
    }

    struct EatParams {
        uint round;
        IBattleRoyaleNFT nft;
        address player;
        uint tokenIndex;
    }
    function eat(mapping(address => uint) storage playersData, EatParams memory p) external {
        uint playerData = playersData[p.player];
        uint characterId = PlayerDataHelper.firstTokenId(playerData);
        uint foodId = _getTokenId(playerData, p.tokenIndex);
        uint heal = Property.decodeFoodProperty(p.nft.tokenProperty(foodId));
        (uint hp, uint maxHP, uint bag) = Property.decodeCharacterProperty(p.nft.tokenProperty(characterId));
        uint hp2 = Math.min(maxHP, hp + heal);
        p.nft.setProperty(characterId, Property.encodeCharacterProperty(hp2, maxHP, bag));

        p.nft.burn(foodId);
        playersData[p.player] = PlayerDataHelper.removeTokenAt(playersData[p.player], p.tokenIndex);

        emit ActionEat(p.round, p.player, hp2 - hp);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
//import "hardhat/console.sol";
//import "../lib/forge-std/src/console.sol";

interface IBattleRoyaleGameV1 {
    enum TileType {
        None, // nothing here, player can pass through, bullet can pass through, not destroyable
        Water, // player cannot pass through, bullet can pass through, not destroyable
        Mountain, // player cannot pass through, bullet cannot pass through, not destroyable
        Wall, // player cannot pass through, bullet cannot pass through, destroyable
        ChestBox // player cannot pass through, bullet cannot pass through, destroyable
    }

    event RegisterGame(uint indexed round, address indexed player, bool indexed isRegister, uint[] tokenIds);
    event ActionMove(uint indexed round, address indexed player, uint startPos, uint[] path);
    event ActionShoot(uint indexed round, address indexed player, uint fromPos, uint targetPos, bool hitSucceed);
    event ActionPick(uint indexed round, address indexed player);
    event ActionDrop(uint indexed round, address indexed player);
    event ActionBomb(uint indexed round, address indexed player, uint fromPos, uint targetPos, uint explosionRange);
    event ActionEat(uint indexed round, address indexed player, uint heal);

    event ActionDefend(uint indexed round, address indexed player, uint defense);
    event ActionDodge(uint indexed round, address indexed player, bool succeed);

    event PlayerHurt(uint indexed round, address indexed player, uint damage);
    event PlayerKilled(uint indexed round, address indexed player);
    event PlayerWin(uint indexed round, address indexed player, uint tokenReward, uint nftReward);

    event TileChanged(uint indexed round, uint pos);

    event TokensOnGroundChanged(uint indexed round, uint pos);

    event GameStateChanged();

    struct GameConfig {
        uint24 needPlayerCount;
        uint24 mapSize;
        // seconds in ont tick
        uint16 tickTime;
        // ticks in one game
        uint16 ticksInOneGame;
        uint16 forceRemoveTicks;
        uint16 forceRemoveRewardToken;
        uint8 moveMaxSteps;
        uint8 chestboxGenerateIntervalTicks;

        uint24 playerRewardToken;
        uint24 winnerRewardToken;
        uint8 winnerRewardNFT;

        uint8 tokenRewardTax;

        string name;
    }

    struct GameState {
        uint8 status;

        uint16 initedTileCount;
        uint24 round;
        uint40 startTime;
        uint16 newChestBoxLastTick;
        
        uint8 shrinkLeft;
        uint8 shrinkRight;
        uint8 shrinkTop;
        uint8 shrinkBottom;

        uint8 shrinkCenterX;
        uint8 shrinkCenterY;
        
        uint16 shrinkTick;
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BATTLE is ERC20Permit, Ownable {

    mapping(address => bool) public games;

    constructor() ERC20Permit("Battle Token") ERC20("Battle Token", "BATTLE") {}

    modifier onlyGame() {
        require(games[msg.sender], "Only Game");
        _;
    }

    /**
     * mints $BATTLE to a recipient
     * @param to the recipient of the $BATTLE
     * @param amount the amount of $BATTLE to mint
     */
    function mint(address to, uint256 amount) external onlyGame {
        _mint(to, amount);
    }

    /**
     * burns $BATTLE from a holder
     * @param from the holder of the $BATTLE
     * @param amount the amount of $BATTLE to burn
     */
    function burn(address from, uint256 amount) external onlyGame {
        _burn(from, amount);
    }

    function setGame(address game, bool enable) external onlyOwner {
        games[game] = enable;
    }
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

library TokenOnGroundHelper {

    /**
     * 0-12: game round
     * 12-16: token count
     * 16-256: max 12 token, 20 bits for one token
     */
    function tokens(uint encodeData, uint currentRound) internal pure returns(uint[] memory tokenIds) {
        if ((encodeData & 0xfff) == currentRound) {
            uint tokenCount = (encodeData >> 12) & 0xf;
            tokenIds = new uint[](tokenCount);
            for (uint i = 0; i < tokenCount; i++) {
                tokenIds[i] = (encodeData >> (16 + i * 20)) & 1048575;
            }
        } else {
            tokenIds = new uint[](0);
        }
    }

    function addToken(uint encodeData, uint currentRound, uint tokenId) internal pure returns(uint) {
        if ((encodeData & 0xfff) == currentRound) {
            uint tokenCount = (encodeData >> 12) & 0xf;
            if (tokenCount < 12) {
                return currentRound | ((tokenCount +1) << 12) | (encodeData & ~(0xffff + (0xfffff << (16 + tokenCount * 20)))) | (tokenId << (16 + tokenCount * 20));
            }
            return encodeData;
        } else {
            return currentRound | (1 << 12) | (tokenId << 16);
        }
    }

    function removeToken(uint encodeData, uint currentRound, uint tokenIndex) internal pure returns(uint) {
        if ((encodeData & 0xfff) == currentRound) {
            uint tokenCount = (encodeData >> 12) & 0xf;
            require(tokenIndex < tokenCount, "RT");
            uint tokenData = encodeData >> 16;
            uint newtokens = (tokenData & ((1 << (tokenIndex * 20)) - 1)) | ((tokenData >> 20) & (type(uint).max << (tokenIndex * 20)));
            return currentRound | ((tokenCount - 1) << 12) | (newtokens << 16);
        } else {
            revert("RT");
        }
    }
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

library Utils {
    function distanceSquare(uint pos1, uint pos2) internal pure returns(uint) {
        uint x1 = pos1 & 0xff;
        uint y1 = (pos1 >> 8) & 0xff;
        uint x2 = pos2 & 0xff;
        uint y2 = (pos2 >> 8) & 0xff;
        uint dx = (x1 > x2) ? (x1 - x2) : (x2 - x1);
        uint dy = (y1 > y2) ? (y1 - y2) : (y2 - y1);
        return dx * dx + dy * dy;
    }

    /**
     * 0-16: nft count
     * 16-256: token count
     */
    function decodeReward(uint encodeData) internal pure returns (uint tokenReward, uint nftReward) {
        return (encodeData >> 16, encodeData & 0xffff);
    }

    function encodeReward(uint tokenReward, uint nftReward) internal pure returns (uint data) {
        return (tokenReward << 16) + nftReward;
    }

    function addReward(uint encodeData, uint tokenReward, uint nftReward) internal pure returns(uint data) {
        (uint r1, uint r2) = decodeReward(encodeData);
        return encodeReward(r1 + tokenReward, r2 + nftReward);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./IBattleRoyaleNFT.sol";
import "./BATTLE.sol";
import "./libraries/Property.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MintRare is Ownable, ReentrancyGuard {

    struct MintInfo {
        uint property;

        uint96 startPrice;

        uint24 supply;
        uint24 mintedCount;
    }

    IBattleRoyaleNFT nft;
    BATTLE battleToken;

    MintInfo[7] public mintInfos;

    constructor(IBattleRoyaleNFT _targetNFT, BATTLE _battleToken) {
        nft = _targetNFT;
        battleToken = _battleToken;
        mintInfos[0] = MintInfo({
            property: Property.encodeCharacterProperty(100, 100, 6),
            startPrice: 50 ether,
            supply: 250,
            mintedCount: 0
        });
        mintInfos[1] = MintInfo({
            property: Property.encodeGunProperty(10, 16, 30, 100),
            startPrice: 40 ether,
            supply: 250,
            mintedCount: 0
        });
        mintInfos[2] = MintInfo({
            property: Property.encodeBombProperty(16, 10, 100),
            startPrice: 30 ether,
            supply: 100,
            mintedCount: 0
        });
        mintInfos[3] = MintInfo({
            property: Property.encodeArmorProperty(100),
            startPrice: 20 ether,
            supply: 100,
            mintedCount: 0
        });
        mintInfos[4] = MintInfo({
            property: Property.encodeRingProperty(6, 100),
            startPrice: 30 ether,
            supply: 100,
            mintedCount: 0
        });
        mintInfos[5] = MintInfo({
            property: Property.encodeFoodProperty(100),
            startPrice: 20 ether,
            supply: 100,
            mintedCount: 0
        });
        mintInfos[6] = MintInfo({
            property: Property.encodeBootsProperty(3, 15),
            startPrice: 30 ether,
            supply: 100,
            mintedCount: 0
        });
    }

    function mint(uint index) external nonReentrant {
        MintInfo memory info = mintInfos[index];
        require(info.mintedCount < info.supply, "sold out");
        battleToken.burn(msg.sender, mintPrice(index));
        mintInfos[index].mintedCount += 1;
        nft.mintByGame(msg.sender, info.property);
    }

    function mintPrice(uint index) public view returns(uint) {
        MintInfo memory info = mintInfos[index];
        if (info.mintedCount >= info.supply) {
            return type(uint).max;
        } 
        return info.startPrice * (info.mintedCount * 4 / info.supply + 1);
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./libraries/Property.sol";
import "./IBattleRoyaleNFT.sol";
import "./IBattleRoyaleNFTRenderer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "@openzeppelin/contracts/utils/Context.sol";

//import "hardhat/console.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract BattleRoyaleNFT is ERC721Enumerable, Ownable, ReentrancyGuard, EIP712, IBattleRoyaleNFT {
    uint public constant MINT_PRICE = 0.0149 ether;
    uint public constant MINT_SUPPLY = 9999;
    uint public constant DEV_MINT_SUPPLY = 499;
    uint public constant MAX_PER_WALLET = 5;

    // 0: cannot mint
    // 1: public mint by people
    // 2: mint by game logic contract
    uint8 public mintStatus = 0;
    uint16 private _devMintCount;

    uint public nextTokenId;

    mapping(address => uint) private _address2mintCount;

    address[] private _games;
    mapping(address => uint) private _game2index;

    // nft property
    mapping(uint => uint) private _properties;

    IBattleRoyaleNFTRenderer public renderer;

    // custom cross chain logic
    bytes32 private constant _CROSS_CHAIN_TYPEHASH =
        keccak256("ClaimByCrossChain(address to,uint256[] data,uint256 nonce)");

    event CrossChainStart(uint indexed nonce, address indexed from, address indexed to, uint[] data);
    event CrossChainFinish(uint indexed nonce);

    address public validator;
    uint public crossChainNonce = 0;
    mapping(uint => bool) public claimedNonce;

    constructor(uint startTokenId) ERC721("Battle Royale NFT", "BattleRoyaleNFT") EIP712("Battle Royale NFT", "1") {
        nextTokenId = startTokenId;
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _burn(tokenId);
    }

    // Ethereum <=> Arbitrum Nova
    function crossChain(address to, uint[] calldata tokenIds) external {
        uint count = tokenIds.length;
        require(count > 0, "No Tokens");
        uint[] memory data = new uint[](count * 2);
        for (uint i = 0; i < count; i++) {
            uint tokenId = tokenIds[i];
            data[i * 2] = tokenId;
            data[i * 2 + 1] = _properties[tokenId];

            burn(tokenId);
            delete _properties[tokenId];
        }
        emit CrossChainStart(crossChainNonce, msg.sender, to, data);
        crossChainNonce += 1;
    }

    function claimByCrossChain(
        address to,
        uint[] calldata data,
        uint nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(!claimedNonce[nonce], "Claimed");
        claimedNonce[nonce] = true;
        bytes32 structHash = keccak256(abi.encode(_CROSS_CHAIN_TYPEHASH, to, data, nonce));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == validator, "claimByCrossChain: invalid signature");

        for(uint i = 0; i < data.length; i += 2) {
            _safeMint(to, data[i]);
            _properties[data[i]] = data[i+1];
        }
        emit CrossChainFinish(nonce);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function mint(uint amount) external payable {
        require(_address2mintCount[msg.sender] + amount <= MAX_PER_WALLET, "mint too many");
        _address2mintCount[msg.sender] += amount;

        require(msg.value >= MINT_PRICE * amount, "not enough money");
        require(mintStatus == 1, "no public mint ");
        require(nextTokenId + amount <= MINT_SUPPLY - DEV_MINT_SUPPLY, "sold out");
        require(msg.sender == tx.origin, "no bot");

        /**
         * Character: 25%
         * Gun: 25%
         * Bomb: 10%
         * Armor: 10%
         * Ring: 10%
         * Food: 10%
         * Boots: 10%
         */
        for (uint i = 0; i < amount; i++) {
            _mintAny(msg.sender, 0x77665544332222211111);
        }
    }

    function _mintAny(address to, uint probability) internal returns (uint) {
        uint seed = uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nextTokenId))
        );
        return _mintToken(to, Property.newProperty(seed, probability));
    }

    function _mintToken(address to, uint property) internal returns (uint) {
        uint tokenId = nextTokenId;
        _properties[tokenId] = property;
        nextTokenId = tokenId + 1;
        _safeMint(to, tokenId);
        return tokenId;
    }

    // to support receiving ETH by default
    receive() external payable {}

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return renderer.tokenURI(tokenId, tokenProperty(tokenId));
    }

    // nft property getter

    function tokenType(uint tokenId) public view returns (uint) {
        return Property.decodeType(_properties[tokenId]);
    }

    function tokenProperty(uint tokenId) public view returns (uint) {
        return _properties[tokenId];
    }

    function games() external view returns (address[] memory) {
        return _games;
    }

    modifier onlyGame() {
        require(_game2index[msg.sender] > 0, "not game");
        _;
    }

    // function getName(uint tokenId) view public returns (string memory name) {
    //     uint property = _properties[tokenId];
    // }

    // only for game
    function setProperty(uint tokenId, uint newProperty) external onlyGame {
        uint oldProperty = _properties[tokenId];
        require(
            Property.decodeType(oldProperty) == Property.decodeType(newProperty) &&
            Property.propertyCount(oldProperty) == Property.propertyCount(newProperty),
            "not same type"
        );
        _properties[tokenId] = newProperty;
    }

    function mintByGame(address to, uint property)
        external
        nonReentrant
        onlyGame
        returns (uint)
    {
        require(mintStatus == 2, "cannot mint by game");
        return _mintToken(to, property);
    }

    // only for owner
    function withdraw() external onlyOwner {
        (bool success,)= owner().call{value: address(this).balance}("");
        require(success);
    }

    function devMint(uint amount) external onlyOwner {
        require(mintStatus == 1, "no mint");
        require(uint(_devMintCount) + amount <= DEV_MINT_SUPPLY, "Sold Out");
        _devMintCount += uint16(amount);
        for (uint i = 0; i < amount; i++) {
            _mintAny(msg.sender, 0x77665544332222211111);
        }
    }

    function setMintStatus(uint8 status) external onlyOwner {
        require(status > mintStatus, "invalid status");
        mintStatus = status;
    }

    function addGame(address game) external onlyOwner {
        require(_game2index[game] == 0, "added");
        _games.push(game);
        _game2index[game] = _games.length;
    }

    function removeGame(address game) external onlyOwner {
        uint index = _game2index[game];
        require(index > 0, "not game");
        uint totalGameCount = _games.length;
        if (index != totalGameCount) {
            address lastGame = _games[totalGameCount - 1];
            _games[index-1] = lastGame;
            _game2index[lastGame] = index;
        }
        _games.pop();
        delete _game2index[game];
    }

    function setRenderer(IBattleRoyaleNFTRenderer newRenderer) external onlyOwner {
        renderer = newRenderer;
    }

    function setValidator(address newValidator) external onlyOwner {
        validator = newValidator;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
import "./IBattleRoyaleNFT.sol";
//import "../lib/forge-std/src/console.sol";

interface IBattleRoyaleNFTRenderer {
    function tokenURI(uint tokenId, uint property) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
import "./IBattleRoyaleNFT.sol";
import "./IBattleRoyaleNFTRenderer.sol";
import "./libraries/Property.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

//import "../lib/forge-std/src/console.sol";

contract BattleRoyaleNFTProperty is IBattleRoyaleNFTRenderer {

    using Strings for uint;

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    bytes private constant _characterData = hex"18180000000000005b3532a33733a47979e8cfbf29377900000000000004924000000000000129248800000000000a4db4910000000000535238da20000000029249b71a44000000029249291a44000000029249a4924400000002926ab515440000000056d6ed6520000000000db6db6a20000000000cb6db5100000000000196db31240000000009ca38db68900000005a49b6db6db20000131a6db6db6db24000d92249b6db72db0800c92249b6db965b610019264db6b4b24b48001b32d96dacd65b48001b66db6da556db48001936db6da4d6c948001573db6db6d24a88001d6edb6dadb6db8800196ecaedadb2da88";

    bytes private constant _gunData = hex"20160000000c0c0d2e30344f4f5964647100000000000000000000120000000000000000004000a6492492492492492492c805a6d24db6e372391b6db6d005a6d24db6dc6e46e36db6d005a6d24db6dc8dc6e46db6d004929225249249249249249000929249244924924924924800125248905100a20000000000125248904900100000000000125248a00800100000000000129244924924900000000000929244924924900000000000929224000000000000000000929224000000000000000004949224000000000000000024a49224000000000000000024a49120000000000000000025249120000000000000000004a491000000000000000000009291000000000000000000009249000000000000000000000248000000000000000000";

    bytes private constant _bombData = hex"1818000000e6a8a0dd452afbbf03885e4305050718161bf6efef0000000000000000000000000000000000000000000000000080000000000000000520000000000000004924080000000000004db4400000000000248db680000000b6db0dcdb28000016ddadd2f28a400000bb5d6ddb6201000005bb6daddb7e0000002dbb6db6b6ea00000035bb6db6ff6d4000016ddb5db6ffeb40000175bb6db6df6b4000016dbb6d76db6b4000016dbb5db6df6a00000035b76db6db6a0000002eb6edb6db5000000005b6edb6db5000000000b6dbaed6800000000016db6eb40000000000005b6d000000000000000000000000000";

    bytes private constant _armorData = hex"181800000000000082796cb8b8b81718185d5f5f403c389c9c9c0000000000000000000002492492492490000014dcb97ef697420000b7d47b6daf9ea84000bf676f499ff15a40067a7fedf7dbf4aa4805c33f6fffdb7e494806293b6fb7db7e4448064d2bfff7fffe6848064dafedb6ff5b48480092676db6fff2124000004a6db6dba4800000004dffb7fda4800000004eabffd5a4800000004ed6ff6dc4800000000cdb25b4840000000009d36da4240000000063724922c4800000005bfbb7f7b8800000005fbdfeff50800000007bd21322d0800000004b9ad574c48000000009249249240000000000000000000000";

    bytes private constant _ringData = hex"1818000000010100744912d8a841e3cd8d6b8acb402908264da100000000000000000000000124924000000000000a71d7892000000000739248f62000000002a491b7ffe48000001ce48dafedbc900000e71b6d7f6cb7900000e6f249ff6db5e2400725b649ffedbebc40052589c97ffdfebc4007244029b7fff237880524402936e48dc6c80524402738db8dc88807258800e59252490800e488001c9b6e48c800e48800139a724908009cb10000726dc88800039624000e6db4400002725892766dbc4000004e4925b16da240000001d96d92691000000001276c564b1000000000009249248000000000000000000000";

    bytes private constant _foodData = hex"181800000008010199772ae0701c8f200eeebc4d1b843f00000000000000000000000000000124924920000000000949c69a840000000255adb6dda8900000155d75baebaea20000a76badb76b6ed44000db6d76daebb6ba40055b5db5db6db5da8806db6db6daed76db48055b6db6db6db6d68805576db6db6db5bd8800abb576b6db6b2a4000c996cb6daedb584004c9325adb75b93908063726d76db6da37080648dd923ae46ec8c806c694b6d92491b90806d32496a8a3721ac8065b524925124ad70800ab6db6db6dadb8400012adb6b75b6e1200000049b6badb848000000001249249200000000000000000000000";

    bytes private constant _bootsData = hex"1818000000010101251f1d3f3a3671756f56545096a49c00000000000000000000000000000000920000000000000000944004800000004904b84125100000005329488a31220000000dcdd692d9a440000001d6b494d1a44000000172d68cd1264000000032d48bd5324000000032b441d5a2000000003634419122000000002eb44175320000000171b442b5220000000a92a44171320000004c92b44259b4000012f44db493b9a20000b934a9244bb1344005591a2492415ab2400092490000015746400000000000017b4a880000000000012f4648000000000000051200000000000000049000000000000000000000";

    function _getColorString(uint red, uint green, uint blue) private pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        buffer[1] = _HEX_SYMBOLS[red & 0xf];
        buffer[0] = _HEX_SYMBOLS[(red >> 4) & 0xf];

        buffer[3] = _HEX_SYMBOLS[green & 0xf];
        buffer[2] = _HEX_SYMBOLS[(green >> 4) & 0xf];

        buffer[5] = _HEX_SYMBOLS[blue & 0xf];
        buffer[4] = _HEX_SYMBOLS[(blue >> 4) & 0xf];
        return string(buffer);
    }


    function _renderImage(bytes memory data) private pure returns (string memory r) {
        uint width = uint8(data[0]);
        uint height = uint8(data[1]);

        require(width * height % 8 == 0, "invalid size");
        
        string[8] memory colors;
        for(uint i = 1; i < 8; i++) {
            colors[i] = _getColorString(uint(uint8(data[2 + i * 3])), uint(uint8(data[2 + i * 3 + 1])), uint(uint8(data[2 + i * 3 + 2])));
        }
        uint index = 0;
        r = "";
        uint offsetX = (32 - width) / 2;
        uint offsetY = 32 - height;

        for (uint i = 26; i < data.length; i += 3) {
            uint24 tempUint;
            assembly {
                tempUint := mload(add(add(data, 3), i))
            }
            uint pixels = tempUint;
            for (uint j = 0; j < 8; j++) {
                uint x = index % width;
                uint y = index / width;
                uint d = (pixels >> (3 * (7 - j))) & 7;
                index += 1;
                if (d > 0) {
                    r = string(abi.encodePacked(r, '<rect fill="#', colors[d], '" x="', (x + offsetX).toString(), '" y="', (y + offsetY).toString(), '" width="1" height="1" />'));
                }
            }
        }
    }

    function _characterTextProperties(uint property) private pure returns (string[] memory r) {
        (uint hp, uint maxHP, uint bagCapacity) = Property.decodeCharacterProperty(property);
        r = new string[](6);
        r[0] = "HP";
        r[1] = hp.toString();

        r[2] = "Max HP";
        r[3] = maxHP.toString();

        r[4] = "Bag Capacity";
        r[5] = bagCapacity.toString();

    }

    function _gunTextProperties(uint property) private pure returns (string[] memory r) {
        (uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) = Property.decodeGunProperty(property);
        r = new string[](8);
        r[0] = "Bullet Count";
        r[1] = bulletCount.toString();

        r[2] = "Shoot Range";
        r[3] = shootRange.toString();

        r[4] = "Bullet Damage";
        r[5] = bulletDamage.toString();

        r[6] = "Triple Damage Chance";
        r[7] = string(abi.encodePacked(tripleDamageChance.toString(), "%"));

    }

    function _bombTextProperties(uint property) private pure returns (string[] memory r) {
        (uint throwRange, uint explosionRange, uint damage) = Property.decodeBombProperty(property);
        r = new string[](6);
        r[0] = "Throw Range";
        r[1] = throwRange.toString();

        r[2] = "Explosion Range";
        r[3] = explosionRange.toString();

        r[4] = "Bomb Damage";
        r[5] = damage.toString();
    }

    function _armorTextProperties(uint property) private pure returns (string[] memory r) {
        (uint defense) = Property.decodeArmorProperty(property);
        r = new string[](2);
        r[0] = "Defense";
        r[1] = defense.toString();
    }

    function _ringTextProperties(uint property) private pure returns (string[] memory r) {
        (uint dodgeCount, uint dodgeChance) = Property.decodeRingProperty(property);
        r = new string[](4);
        r[0] = "Dodge Count";
        r[1] = dodgeCount.toString();

        r[2] = "Dodge Chance";
        r[3] = string(abi.encodePacked(dodgeChance.toString(), "%"));
    }

    function _foodTextProperties(uint property) private pure returns (string[] memory r) {
        (uint heal) = Property.decodeFoodProperty(property);
        r = new string[](2);
        r[0] = "Heal HP";
        r[1] = heal.toString();
    }

    function _bootsTextProperties(uint property) private pure returns (string[] memory r) {
        (uint usageCount, uint moveMaxSteps) = Property.decodeBootsProperty(property);
        r = new string[](4);
        r[0] = "Usage Count";
        r[1] = usageCount.toString();

        r[2] = "Max Move Distance";
        r[3] = moveMaxSteps.toString();
    }

    function _renderTextProperties(string[] memory properties, string memory name) private pure returns (string memory r) {
        r = string(abi.encodePacked('<text x="31" y="6" class="title">', name, '</text>'));
        for (uint i = 0; i < properties.length; i += 2) {
            r = string(abi.encodePacked(r, '<text x="1" y="', (i * 1 + 2).toString(), '" class="base">', properties[i], ': ',  '<tspan class="value">', properties[i+1], '</tspan></text>'));
        }
    }

    struct MetaDataParams {
        string name;
        uint tokenId;
        string description;
        string[] textProperties;
        bytes renderData;
        string color1;
        string color2;
    }
    function _genMetadata(MetaDataParams memory p) private pure returns (string memory) {
        bytes memory svg = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 32"><style>.base { fill: black; font-family: serif; font-size: 1px; font-weight: 500; } .title{ fill: black; font-family: serif; font-size: 2.5px; text-anchor: end;font-weight: 600 } .hint { fill: gray; font-family: serif; font-size: 1px; font-weight: 600; text-anchor: end; }.value{font-weight: 600;} </style><defs><radialGradient id="RadialGradient1"><stop offset="5%" stop-color="', p.color1, '"/><stop offset="75%" stop-color="',p.color2, '" /></radialGradient></defs><circle r="32" cx="16" cy="16" fill="url(#RadialGradient1)"/><text x="31" y="2" class="hint">play game on battle-royale.xyz</text>');

        svg = abi.encodePacked(svg, _renderTextProperties(p.textProperties, p.name), _renderImage(p.renderData), '</svg>');

        // if (keccak256(bytes(p.name)) == keccak256("Character")) {
        //     console.log("svg", string(svg));
        //     revert("Stop");
        // }
        
        bytes memory attributes = "[";
        for (uint i = 0; i < p.textProperties.length; i += 2) {
            attributes = abi.encodePacked(attributes, i == 0 ? '' : ',', '{"trait_type":"', p.textProperties[i], '","value":"', p.textProperties[i+1], '"}');
        }
        attributes = abi.encodePacked(attributes, ']');

        bytes memory d = abi.encodePacked('{"name":"', p.name, ' #', p.tokenId.toString(), '","description":"', p.description, '","image": "data:image/svg+xml;base64,', Base64.encode(svg), '","attributes":', attributes, '}');
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(d)));
    }

    function tokenURI(uint tokenId, uint property) external pure returns (string memory) {
        uint nftType = Property.decodeType(property);
        if (nftType == Property.NFT_TYPE_CHARACTER) {
            return _genMetadata(MetaDataParams({
                name: "Character",
                tokenId: tokenId,
                description: "Must have the character NFT to play game",
                textProperties: _characterTextProperties(property),
                renderData: _characterData,
                color1: "#fff2f2",
                color2: "#ffe6e6"
            }));
        } else if (nftType == Property.NFT_TYPE_GUN) {
            return _genMetadata(MetaDataParams({
                name: "Gun",
                tokenId: tokenId,
                description: "Shoot others with the gun",
                textProperties: _gunTextProperties(property),
                renderData: _gunData,
                color1: "#fffdf2",
                color2: "#fffbe6"
            }));
        } else if (nftType == Property.NFT_TYPE_BOMB) {
            return _genMetadata(MetaDataParams({
                name: "Bomb",
                tokenId: tokenId,
                description: "Throw the bomb to kill more people",
                textProperties: _bombTextProperties(property),
                renderData: _bombData,
                color1: "#f7fff2",
                color2: "#eeffe6"
            }));
        } else if (nftType == Property.NFT_TYPE_ARMOR) {
            return _genMetadata(MetaDataParams({
                name: "Armor",
                tokenId: tokenId,
                description: "Wear the armor to defend",
                textProperties: _armorTextProperties(property),
                renderData: _armorData,
                color1: "#f2fff9",
                color2: "#e6fff2"
            }));
        } else if (nftType == Property.NFT_TYPE_RING) {
            return _genMetadata(MetaDataParams({
                name: "Ring",
                tokenId: tokenId,
                description: "Wear the ring to dodge bullets",
                textProperties: _ringTextProperties(property),
                renderData: _ringData,
                color1: "#f2fbff",
                color2: "#e6f7ff"
            }));
        } else if (nftType == Property.NFT_TYPE_FOOD) {
            return _genMetadata(MetaDataParams({
                name: "Food",
                tokenId: tokenId,
                description: "Eat food to heal (+HP)",
                textProperties: _foodTextProperties(property),
                renderData: _foodData,
                color1: "#f4f2ff",
                color2: "#eae6ff"
            }));
        } else if (nftType == Property.NFT_TYPE_BOOTS) {
            return _genMetadata(MetaDataParams({
                name: "Boots",
                tokenId: tokenId,
                description: "Wear the boots to move further",
                textProperties: _bootsTextProperties(property),
                renderData: _bootsData,
                color1: "#fff2ff",
                color2: "#ffe6ff"
            }));
        } else {
            revert("Unknown nft type");
        }
    }

    function characterProperty(uint property) public pure returns(uint hp, uint maxHP, uint bagCapacity) {
        return Property.decodeCharacterProperty(property);
    }

    function gunProperty(uint property) public pure returns(uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) {
        return Property.decodeGunProperty(property);
    }

    function bombProperty(uint property) public pure returns(uint throwRange, uint explosionRange, uint damage) {
        return Property.decodeBombProperty(property);
    }

    function armorProperty(uint property) public pure returns(uint defense) {
        return Property.decodeArmorProperty(property);
    }

    function ringProperty(uint property) public pure returns(uint dodgeCount, uint dodgeChance) {
        return Property.decodeRingProperty(property);
    }

    function foodProperty(uint property) public pure returns(uint heal) {
        return Property.decodeFoodProperty(property);
    }

    function bootsProperty(uint property) public pure returns(uint usageCount, uint moveMaxSteps) {
        return Property.decodeBootsProperty(property);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}