/**
 *Submitted for verification at Arbiscan on 2022-06-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

pragma solidity 0.8.0;

contract testApp {

    uint256 first;
    uint256 second;

    function returnMeSingle() public pure returns (string memory) {
        return "HERE I AM WITH A TEST CASE";
    }

    function returnMeDouble() public pure returns (string memory) {
        return "HERE I AM WITH ANOTHER TEST CASE BUT THIS ONE IS A LOT LONGER AND MAY CAUSE PROBLEMS WITH A MERE 64 HEX-BYTE CHARACTER.";
    }

    function returnMeSingleTrigger() public returns (string memory) {
        first = first + 1;
        return "HERE I AM WITH A TEST CASE";
    }

    function returnMeDoubleTrigger() public returns (string memory) {
        second = second + 1;
        return "HERE I AM WITH ANOTHER TEST CASE BUT THIS ONE IS A LOT LONGER AND MAY CAUSE PROBLEMS WITH A MERE 64 HEX-BYTE CHARACTER.";
    }

    function test() public pure returns (string[3] memory) {
        return ["aaa","bbbb","HERE I AM WITH ANOTHER TEST CASE BUT THIS ONE IS A LOT LONGER AND MAY CAUSE PROBLEMS WITH A MERE 64 HEX-BYTE CHARACTER."];
    }

    function testByte() public pure returns (bytes memory) {
        uint8 u8 = 1;
        bytes memory bts = new bytes(32);
        bytes32 b32 = "Terry A. Davis";
        assembly {
            mstore(add(bts, /*BYTES_HEADER_SIZE*/32), u8)
            mstore(add(bts, /*BYTES_HEADER_SIZE*/32), b32)
        }
        return bts;
    }

  function testFixByte() public pure returns (bytes[2] memory) {
     bytes memory a = abi.encodePacked(uint256(123));
        bytes memory b = abi.encodePacked(uint256(456));
        return [a,b];
    }
}