// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OTC {
    address immutable public owner;

    uint256 public constant USDC_AMOUNT = 7_500e6;
    uint256 public constant BOOP_AMOUNT = 50_000_000e18;

    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant BOOP = 0x13A7DeDb7169a17bE92B0E3C7C2315B46f4772B3;

    address public constant BUYER = 0xE4e44E8790a25a13dcDaC7c71da8Dc638791b873;

    constructor() {
        owner = msg.sender;
    }

    function swap() external {
        require(msg.sender == BUYER, "");
        IERC20(USDC).transferFrom(msg.sender, owner, USDC_AMOUNT);
        IERC20(BOOP).transfer(msg.sender, BOOP_AMOUNT);
    }

    function retrieve(IERC20 token, uint256 am) external {
        require(msg.sender == owner, "");

        token.transfer(owner, am);
    }
}