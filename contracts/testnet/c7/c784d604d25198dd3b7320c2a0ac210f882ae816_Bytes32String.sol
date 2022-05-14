/**
 *Submitted for verification at Arbiscan on 2022-05-13
*/

pragma solidity >=0.8.0 <0.9.0;

contract Bytes32String {
    function bytes32Function(bytes32 what) external pure returns (uint, bytes32) {
        string memory str = "abc";
        bytes32 str_bytes32 = bytes32(bytes(str));
        if (what == "abc") return (1, str_bytes32);
        else return (2, str_bytes32);
    }
}