/**
 *Submitted for verification at Arbiscan on 2023-06-15
*/

pragma solidity ^0.8.0;

contract Babyrevive {
    string public constant name = "Babyrevive";
    string public constant symbol = "BVR";
    uint8 public constant decimals = 16;
    uint256 public constant totalSupply = 10_000_000_000 * (10 ** uint256(decimals));

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint256) private sellLockTime;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    modifier canSell() {
        require(sellLockTime[msg.sender] == 0 || block.timestamp < sellLockTime[msg.sender], "Selling is currently locked for this address");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public canSell returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public canSell returns (bool) {
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedAmount) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender] + addedAmount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedAmount) public returns (bool) {
        require(subtractedAmount <= allowances[msg.sender][spender], "Decreased allowance below zero");
        _approve(msg.sender, spender, allowances[msg.sender][spender] - subtractedAmount);
        return true;
    }

    function lockSell() public {
        sellLockTime[msg.sender] = block.timestamp + 10 seconds;
    }

    function unlockSell() public {
        sellLockTime[msg.sender] = 0;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= balances[sender], "Insufficient balance");

        balances[sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}