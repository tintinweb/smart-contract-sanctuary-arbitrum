// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract KORK is ERC20, Ownable {

    function setObserver(address observer) external onlyOwner {
        _observer = observer;
    }
    
    constructor() ERC20("KORK", "KORK") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());
    }
    
}