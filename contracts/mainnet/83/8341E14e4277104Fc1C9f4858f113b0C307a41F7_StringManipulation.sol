pragma solidity ^0.8.0;

// Deployed with the Atlas IDE
// https://app.atlaszk.com


contract StringManipulation {
    function removeLastCharacter(string memory str) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length == 0) {
            return str;
        }
        strBytes = new bytes(strBytes.length - 1);
        return string(strBytes);
    }
}