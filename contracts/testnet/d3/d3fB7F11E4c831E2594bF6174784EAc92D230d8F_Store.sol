// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Store {
    string public text;

    function store(string memory text_) public {
        text = text_;
    }
}