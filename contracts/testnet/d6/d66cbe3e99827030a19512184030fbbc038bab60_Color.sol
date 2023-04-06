// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//import "forge-std/console.sol";

library Color {
    //    function randomColor(uint256 tokenId) public pure returns (string memory) {
    //        uint256 random = uint256(keccak256(abi.encodePacked(tokenId)));
    //        string memory color = "#";
    //        for (uint i = 0; i < 6; i++) {
    //            color = string(
    //                abi.encodePacked(
    //                    color,
    //                    toHexChar(uint8((random >> (i * 8)) & 0xff))
    //                )
    //            );
    //        }
    //        return color;
    //    }
    //
    //    function toHexChar(uint8 num) internal pure returns (bytes1) {
    //        if (num < 10) {
    //            return bytes1(uint8(bytes1("0")) + num);
    //        } else {
    //            return bytes1(uint8(bytes1("a")) + (num - 10));
    //        }
    //    }

    function randomColor(uint256 tokenId) public view returns (string memory) {
        //        tokenId = 6;

        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    block.number,
                    tokenId
                )
            )
        );
        //        uint256 random = uint256(keccak256(abi.encodePacked(tokenId)));
        bytes memory color = new bytes(3);
        for (uint256 i = 0; i < 3; i++) {
            color[i] = bytes1(uint8(random >> (i * 8)));
            //            console.log(i);
            //            console.log("=>");
            //            console.log(random);
            //            console.log(random >> (i * 8));
        }
        return bytesToHexString(color);
    }

    function bytesToHexString(
        bytes memory data
    ) internal pure returns (string memory) {
        bytes memory hexAlphabet = "0123456789abcdef";
        bytes memory result = new bytes(2 * data.length);
        for (uint256 i = 0; i < data.length; i++) {
            result[2 * i] = hexAlphabet[uint8(data[i] >> 4)];
            result[2 * i + 1] = hexAlphabet[uint8(data[i] & 0x0f)];
        }
        return string(result);
    }
}