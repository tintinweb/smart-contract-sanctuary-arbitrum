// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./ERC20.sol";

contract Bobac is ERC20 {
    using SafeMath for uint256;
    uint256 bobac = 0xB0BAC;

    constructor (uint256 totalsupply_) public ERC20("BOBAC", "BOBAC") {
        _mint(_msgSender(), totalsupply_);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

}