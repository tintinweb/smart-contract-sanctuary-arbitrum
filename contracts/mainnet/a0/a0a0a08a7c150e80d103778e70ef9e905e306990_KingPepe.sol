// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./ERC20.sol";

contract KingPepe is ERC20 {
    using SafeMath for uint256;
    uint256 kingpepe = 0xA0A0A0A0;

    constructor (uint256 totalsupply_) public ERC20("KINGPEPE", "KINGPEPE") {
        _mint(_msgSender(), totalsupply_);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

}