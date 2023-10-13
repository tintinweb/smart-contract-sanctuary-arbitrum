// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract SimplifyTradingToken {
    string public name;

    string public symbol;

    uint256 public decimals;

    constructor(string memory _name, string memory _symbol, uint256 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}