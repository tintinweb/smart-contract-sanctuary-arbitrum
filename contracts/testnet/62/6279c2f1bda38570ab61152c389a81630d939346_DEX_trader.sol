/**
 *Submitted for verification at Arbiscan on 2023-02-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7  <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
     address sender,
     address recipient,
     uint amount
     ) external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract DEX_trader {
    constructor() {
    }

    function isTrader(address pool) public view returns (uint amount) {
        address WETH = 0xe44f732337780EB1cEd38Afd641Bdf3056C2Ea2E;
     amount = IERC20(WETH).balanceOf(pool);
        return amount;
    }
}