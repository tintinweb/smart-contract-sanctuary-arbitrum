//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Foo {
    function bar() external pure returns (string memory) {
        return "baz";
    }
}