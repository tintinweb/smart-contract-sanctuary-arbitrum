// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VerifyIPFS {
  error NotCIDv0();
  error NotCIDv1();
  error NotCID();

  function isCID(string memory hash) public pure returns (bool) {
    if (isCIDv1(hash)) {
      return true;
    }
    revert NotCID();
  }

  function isCIDv1(string memory hash) public pure returns (bool) {
    bytes memory b = bytes(hash);

    // Check if it starts with 'b' for Base32 encoding of CIDv1
    if (b[0] != bytes1("b")) {
      revert NotCIDv1();
    }

    // Base32 character set check for the rest of the hash
    for (uint i = 1; i < b.length; i++) {
      if ((b[i] < "2" || b[i] > "7") && (b[i] < "a" || b[i] > "z")) {
        revert NotCIDv1();
      }
    }

    return true;
  }
}