// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.17;

import "./ERC20.sol";

contract BEER is ERC20 {
    constructor() ERC20("Beer Finance", "BEER") {
        _mint(msg.sender, 10_000_000 * 1e18);
    }
}