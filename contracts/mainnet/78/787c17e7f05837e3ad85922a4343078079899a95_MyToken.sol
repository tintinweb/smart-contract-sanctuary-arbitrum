// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("Meta Human", "MTH") {
        _mint(msg.sender, 500000000000000000000000000);

    }
}