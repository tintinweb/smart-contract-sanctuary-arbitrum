// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract HFSP is ERC20 {

    constructor() ERC20("HFSP", "HFSP") {
        _mint(msg.sender, 100000000000000e18);
    }

}