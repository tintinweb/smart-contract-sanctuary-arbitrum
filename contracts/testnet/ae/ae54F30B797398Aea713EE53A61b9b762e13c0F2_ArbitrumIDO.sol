// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";

contract ArbitrumIDO is Ownable {

    // constant
    uint constant TOKEN_PRICE = 0.0000025 ether;
    uint constant BUY_TOKEN_MAX_BUYER = 4000;
    uint constant MAXIUM_PURCHASE_ADDRESS = 5000;
    IERC20 immutable DARB;

    // attribute
    uint public purchaseCount;
    mapping(address => uint) public buyAmount;
    mapping(address => bool) public bought;

    event BuyToken(address indexed buyer, uint indexed amount);

    constructor(address tokenAddress) {
        DARB = IERC20(tokenAddress);
    }

    // buyToken
    function buyToken(uint amount) payable external returns (bool) {
        require(msg.value == amount * TOKEN_PRICE, "Exceeded the purchase amount");
        require(amount > 0, "amount of errors"); 
		require(buyAmount[msg.sender] + amount <= BUY_TOKEN_MAX_BUYER, "Exceeded the total purchase amount");

        if(!bought[msg.sender]) {
            require(purchaseCount <= MAXIUM_PURCHASE_ADDRESS, "Exceeded the purchase quantity");
            purchaseCount++;
            bought[msg.sender] = true;
        }

        buyAmount[msg.sender] += amount;
        DARB.transfer(msg.sender, amount);

        emit BuyToken(msg.sender, msg.value);
        return true;
    }

    function getETHPool() external view returns (uint256) {
        return address(this).balance;
    }

    function getIDOPool() external view returns (uint256) {
        return DARB.balanceOf(address(this));
    }

    // onlyOwner
    function transferTokens() external onlyOwner {
        DARB.transfer(msg.sender, DARB.balanceOf(address(this)));
    }

    function transferETH() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

}