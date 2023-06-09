// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";

struct BuyerInfo {
    uint amount;
    bool bought;
}

contract ArbitrumIDO is Ownable {

    // constant
    uint constant TOKEN_PRICE = 0.0000025 ether;
    uint constant BUY_TOKEN_MAX_BUYER = 4000;
    uint constant MAXIUM_PURCHASE_ADDRESS = 5000;
    IERC20 immutable DARB;

    // attribute
    uint public withdrawTime;
    bool public start;
    address[] public buyer;
    mapping(address => BuyerInfo) public buyerInfo;

    event BuyToken(address indexed buyer, uint indexed amount);
    event WithdrawToken(address indexed withdrawer, uint indexed amount);

    constructor(address tokenAddress) {
        DARB = IERC20(tokenAddress);
        withdrawTime = block.timestamp + 15 days;
    }

    // buy
    function buyToken(uint amount) payable external returns (bool) {
        require(start, "has not started");
        require(block.timestamp <= withdrawTime, "Beyond the purchase time");
        require(amount * TOKEN_PRICE == msg.value, "Exceeded the purchase amount");
        require(amount > 0, "amount of errors"); 
		require(buyerInfo[msg.sender].amount + amount <= BUY_TOKEN_MAX_BUYER, "Exceeded the total purchase amount");

        if(!buyerInfo[msg.sender].bought) {
            buyer.push(msg.sender);
            require(buyer.length <= MAXIUM_PURCHASE_ADDRESS, "Exceeded the purchase quantity");
            buyerInfo[msg.sender].bought = true;   
        }

        buyerInfo[msg.sender].amount += amount;

        emit BuyToken(msg.sender, msg.value);
        return true;
    }

    // withdraw
    function withdrawToken() external returns (bool) {
        require(block.timestamp >= withdrawTime, "Withdrawal time has not expired");
        require(buyerInfo[msg.sender].bought, "You didn't buy");
        require(buyerInfo[msg.sender].amount > 0, "Does not hold any amount");

        uint amount = buyerInfo[msg.sender].amount;
        buyerInfo[msg.sender].amount = 0;
        DARB.transfer(msg.sender, amount * 1 ether);

        emit WithdrawToken(msg.sender, amount);
        return true;
    }

    function getETHPool() external view returns (uint256) {
        return address(this).balance;
    }

    function getBuyerSize() external view returns (uint256) {
        return buyer.length;
    }

    function getIDOPool() external view returns (uint256) {
        return DARB.balanceOf(address(this));
    }

    // onlyOwner
    function startIDO() external onlyOwner {
        start = true;
    }

    function setWithdrawTime(uint time) external onlyOwner {
        withdrawTime = time;
    }

    function transferTokens() external onlyOwner {
        DARB.transfer(owner(), DARB.balanceOf(address(this)));
    }

    function transferETH() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

}