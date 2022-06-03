//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './interfaces/IERC20.sol';

contract MyContract{
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == owner);
        uint value = address(this).balance;
        (bool success, ) = msg.sender.call{value:value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    function withdrawToken(IERC20 token) public {
        require(msg.sender == owner);
        uint balance = token.balanceOf(address(this));
        token.transfer(msg.sender,balance);
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}