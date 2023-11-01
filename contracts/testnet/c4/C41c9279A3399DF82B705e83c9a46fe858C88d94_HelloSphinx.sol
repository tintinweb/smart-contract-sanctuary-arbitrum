// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract HelloSphinx {
    uint public shouldRevert = 0;
    uint8 public myNumber;
    address public myAddress;

    constructor(uint8 _myNumber, address _myAddress) {
        myNumber = _myNumber;
        myAddress = _myAddress;
    }

    function increment() public {
        myNumber += 1;
    }

    function set(address _myAddress) public {
        myAddress = _myAddress;
    }

    function doRevert() public {
        if (block.chainid == 59140 && block.number > 50) {
            revert("revert");
        }
        myNumber = 1;
    }
}