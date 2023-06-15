// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract UCB is ERC20, ERC20Burnable{

    constructor() ERC20("UltraCarbon", "UCB") {
        uint256 total = 2000000000 * (10 ** 8);
        _mint(_msgSender(), total);
    }
}