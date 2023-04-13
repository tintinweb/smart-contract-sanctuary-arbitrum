// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IERC20 {
    function balanceOf(address) external view returns (uint);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Locker {
    address public constant LP = 0x730F057f76ec04426A816015c2e1960230f2fc48;     // WETH/AGI pair
    uint public unlock_time = 1712966400;   // Sat Apr 13 2024 00:00:00 GMT+0
    mapping (address => uint) public locked_balances;

    constructor() {
        
    }

    function lock(uint _amount) external {
        require(IERC20(LP).balanceOf(msg.sender) >= _amount, "Not enough balance");
        IERC20(LP).transferFrom(msg.sender, address(this), _amount);
        locked_balances[msg.sender] += _amount;
    }

    function unlock() external {
        require(block.timestamp >= unlock_time, "locked time");
        require(locked_balances[msg.sender] >= 0, "locked balance invalid");
        IERC20(LP).transfer(msg.sender, locked_balances[msg.sender]);
        locked_balances[msg.sender] = 0;

    }
}