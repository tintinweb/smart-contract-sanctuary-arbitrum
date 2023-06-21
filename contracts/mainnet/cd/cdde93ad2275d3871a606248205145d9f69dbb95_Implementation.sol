// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Implementation {
    uint256 public immutable var1;
    uint256 public immutable var2;
    uint256 public var3;

    constructor(uint256 _var1, uint256 _var2, uint256 _var3) {
        var1 = _var1;
        var2 = _var2;
        var3 = _var3;
    }

    function setVar3(uint256 _var3) external {
        var3 = _var3;
    }
}