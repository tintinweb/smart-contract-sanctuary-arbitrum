/**
 *Submitted for verification at Arbiscan on 2023-04-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Whitelist {
    uint8 public maxWhitelistedAddresses;

    mapping(address => bool) public whiteListedAddress;
    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhiteListAddresses) {
        maxWhitelistedAddresses = _maxWhiteListAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whiteListedAddress[msg.sender], "user Already exit");
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "uint8 public numAddressesWhitelisted;"
        );

        whiteListedAddress[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}