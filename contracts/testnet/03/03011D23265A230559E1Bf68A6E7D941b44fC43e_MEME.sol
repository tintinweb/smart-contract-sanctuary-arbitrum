// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract MEME is ERC20 {
    constructor() ERC20("MEME", "MEME") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }
}