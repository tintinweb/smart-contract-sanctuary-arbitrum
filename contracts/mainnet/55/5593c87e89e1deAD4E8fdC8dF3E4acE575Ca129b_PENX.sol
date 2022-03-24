// SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";


contract PENX is ERC20 {
    constructor(uint256 initialSupply) ERC20("Pen-X Governance Token", "PENX") {
        _mint(msg.sender, initialSupply);
    }
}