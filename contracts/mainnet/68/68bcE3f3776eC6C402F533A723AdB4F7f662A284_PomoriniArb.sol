// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract PomoriniArb {
    string public cryptoCulture;

    function setCryptoCulture(string memory _cryptoCulture) public {
        cryptoCulture = _cryptoCulture;
    }

    function getCryptoCulture() public view returns (string memory) {
        return cryptoCulture;
    }
}