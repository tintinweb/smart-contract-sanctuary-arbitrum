// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20Permit} from "./ERC20.sol";

contract Token is ERC20Permit {
    error Unauthorized();

    mapping(address => bool) public exec;

    event SetExec(address indexed who, bool can);

    constructor() ERC20Permit("Rodeo", "RDO", 18) {
        exec[msg.sender] = true;
        emit SetExec(msg.sender, true);
    }

    function setExec(address who, bool can) public {
        if (!exec[msg.sender]) revert Unauthorized();
        exec[who] = can;
        emit SetExec(who, can);
    }

    function mint(address to, uint256 amount) public {
        if (!exec[msg.sender]) revert Unauthorized();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        if (!exec[msg.sender]) revert Unauthorized();
        _burn(from, amount);
    }
}