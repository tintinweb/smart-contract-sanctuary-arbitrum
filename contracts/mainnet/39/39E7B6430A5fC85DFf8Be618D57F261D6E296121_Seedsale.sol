// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Seedsale {
    address public owner;
    IERC20 public xEMToken;
    IERC20 public usdt;
    uint256 public price = 800; // Price per token in the smallest unit of USDT
    uint256 public minPurchase = 0.1 * 1e6; // 0.1 USDT in smallest unit
    uint256 public maxPurchase = 1000 * 1e6; // 1000 USDT in smallest unit
    address public treasury = 0xE4f2b548b2bE58969E4E3a953094638cdd87402a;
    bool public isPresaleCompleted;

    event PresaleEnded();

    constructor() {
        owner = msg.sender;
        xEMToken = IERC20(0xb46a68B09ec6c1C62D26419791B491F28eC84399);
        usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); // Corrected checksum address
        isPresaleCompleted = false;
    }

function buyTokens(uint256 usdtAmount) external {
        require(!isPresaleCompleted, "Presale is completed");
        require(usdtAmount >= minPurchase && usdtAmount <= maxPurchase, "Purchase amount out of range");
        require(usdt.allowance(msg.sender, address(this)) >= usdtAmount, "Check the USDT allowance");
        uint256 tokenAmount = usdtAmount * 1e6 / price;
        require(xEMToken.balanceOf(address(this)) >= tokenAmount, "Not enough tokens left for sale");
        
        usdt.transferFrom(msg.sender, treasury, usdtAmount);
        xEMToken.transfer(msg.sender, tokenAmount);
    }

    function endPresale() external {
        require(msg.sender == owner, "Only owner can end the presale");
        require(!isPresaleCompleted, "Presale is already completed");
        isPresaleCompleted = true;
        emit PresaleEnded();
    }

    function withdrawTokens() external {
        require(msg.sender == owner, "Only owner can withdraw tokens");
        require(isPresaleCompleted, "Presale is not completed");
        uint256 amount = xEMToken.balanceOf(address(this));
        xEMToken.transfer(owner, amount);
    }
}