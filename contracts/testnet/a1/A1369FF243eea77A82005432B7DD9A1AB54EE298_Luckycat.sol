/**
 *Submitted for verification at Arbiscan on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Luckycat {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address private tokenOwner;

    uint256 private constant TAX_FEE = 3; // 3% 交易税
    uint256 private constant JACKPOT_FEE = 50; // 50% 奖金比例
    uint256 private constant JACKPOT_INTERVAL = 5 minutes; // 开奖时间间隔

    uint256 private jackpotTimer;
    uint256 private jackpotPool;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply;
        tokenOwner = msg.sender;
        balances[tokenOwner] = totalSupply;
        jackpotTimer = block.timestamp + JACKPOT_INTERVAL;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function getAllowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function burn(uint256 amount) external {
        require(amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balances[sender], "Insufficient balance");

        if (recipient == address(this) && block.timestamp >= jackpotTimer) {
            _executeJackpot();
        }

        uint256 taxAmount = amount * TAX_FEE / 100;
        uint256 transferAmount = amount - taxAmount;

        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[address(this)] += taxAmount;

        jackpotPool += taxAmount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(this), taxAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _executeJackpot() internal {
        require(jackpotPool > 0, "Jackpot pool is empty.");

        uint256 jackpotAmount = jackpotPool * JACKPOT_FEE / 100;
        balances[address(this)] -= jackpotAmount;
        balances[msg.sender] += jackpotAmount;
        totalSupply -= jackpotPool - jackpotAmount;

        jackpotPool = 0;
        jackpotTimer = block.timestamp + JACKPOT_INTERVAL;

        emit Transfer(address(this), msg.sender, jackpotAmount);
        emit Transfer(address(this), address(0), jackpotPool - jackpotAmount);
    }
}