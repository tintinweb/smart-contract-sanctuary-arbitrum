/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract GBLock {
    IERC20 public token;
    address public admin; 
    uint256 public lockDuration;
    uint256 public totalAmount;
    uint256 public lockTimestamp;

    constructor() {
        admin = msg.sender;
        token = IERC20(0xbCAd8E85669A3fC9eA9B5d692Bd8BDcC2464df31);
        lockDuration = 365 days;
    }

    function lock() public {
        require(msg.sender == admin, "Only owner can call this function");
        totalAmount = token.balanceOf(address(this));
        lockTimestamp = block.timestamp;
    }
    
    function redeem() public {
        require(msg.sender == admin, "Only owner can call this function");
        uint l = (block.timestamp - lockTimestamp)/lockDuration;
        l = l>=4?4:l;
        uint256 continueLock = totalAmount * (4 - l) / 4;
        token.transfer(admin, token.balanceOf(address(this)) - continueLock);
    }

}