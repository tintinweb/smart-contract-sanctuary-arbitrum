/**
 *Submitted for verification at Arbiscan.io on 2024-04-21
*/

pragma solidity ^0.8.0;

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

contract BuyCRCForUSDT {
    // Constructor
    constructor() {}

      uint256 ratio = 2; // 1 usdt = 2 crc
       address receiveUsdtAddress = 0x407F96C79A411096103eAe11c9746cAEF2187c17;
        address crcAddress  = 0xe4177C1400A8Eee1799835DcDe2489c6f0D5d616;
        address usdtAddress = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    function buyUsdtForCrc(uint256 amount) public {
     require(amount >= 10, "less than 10 usdt");

        IERC20 crcToken = IERC20(crcAddress);
        IERC20 usdtToken = IERC20(usdtAddress);

        usdtToken.transferFrom(msg.sender, receiveUsdtAddress, amount * 10**6);
        crcToken.transferFrom(receiveUsdtAddress, msg.sender, amount * ratio * 10**18);
    }
    
}