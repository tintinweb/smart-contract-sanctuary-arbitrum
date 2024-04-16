// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256); // Add balanceOf function
}

contract Seedsale {
    address public admin;
    IERC20 public xEM; // Assuming xEM is an ERC20 token
    address public treasuryAddress = 0xE4f2b548b2bE58969E4E3a953094638cdd87402a;
    uint256 public xEMPrice = 800000000000000; // 0.0008 * 10^18 (assuming 18 decimals)
    uint256 public minBuyAmount = 1 ether;
    uint256 public maxBuyAmount = 1000 ether;
    
    event TokensPurchased(address indexed buyer, uint256 amountPaid, uint256 amountReceived);

    constructor(address _xEM) {
        admin = msg.sender;
        xEM = IERC20(_xEM);
    }

    function buyTokens(uint256 usdtAmount) external {
        require(usdtAmount >= minBuyAmount, "Minimum buy amount not met");
        require(usdtAmount <= maxBuyAmount, "Maximum buy amount exceeded");
        
        uint256 xEMAmount = usdtAmount * (10**18) / xEMPrice;
        
        require(xEM.balanceOf(address(this)) >= xEMAmount, "Insufficient xEM balance in the contract");
        
        require(xEM.transfer(msg.sender, xEMAmount), "Failed to transfer xEM tokens");
        
        emit TokensPurchased(msg.sender, usdtAmount, xEMAmount);
    }

    function withdrawXEM() external {
        require(msg.sender == admin, "Only admin can withdraw");
        uint256 balance = xEM.balanceOf(address(this));
        require(xEM.transfer(treasuryAddress, balance), "Failed to transfer xEM tokens");
    }
}