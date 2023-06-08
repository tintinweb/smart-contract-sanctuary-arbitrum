//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";

contract DefendArbitrum is ERC20 {

    constructor(string memory name, string memory symbol, uint totalSupply) ERC20(name, symbol, totalSupply) {
        
    }

}