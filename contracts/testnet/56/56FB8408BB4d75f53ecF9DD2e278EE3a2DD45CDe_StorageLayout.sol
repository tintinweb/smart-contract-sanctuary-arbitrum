// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageLayout {
  
  uint256 a = 1;
  uint256 b = 2;
  bytes32 aa = "a";
  uint256[] c = [1,2,3];
  mapping(uint256 => uint256) m;
  bytes bb = "b";
  bytes1[] cc = [bytes1(0x65), 0x64, 0x32];
  bytes16 aaa = "a";
  bytes16 bbb = "b";
  bytes s = "b";

  constructor() {
    m[23] = 9;
    m[2] = 7;
  }

  function append_to_c() public {
    uint256 x = c[c.length - 1] + 1;
    c.push(x);
  }


}