/**
 *Submitted for verification at Arbiscan on 2023-05-16
*/

pragma solidity ^0.8.0;

contract PEPE {
    string public constant name = "PEPE";
    string public constant symbol = "PEPE";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 10000000 * 10**uint(decimals); // 总供应量，以最小单位计算
    mapping(address => uint256) public balanceOf; // 每个地址持有的代币余额
    mapping(address => mapping(address => uint256)) public allowance; // 以地址为 key，记录允许其他地址转移的代币数量

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply; // smart contract 部署者自动获得所有代币
    }

    function transfer(address to, uint256 amount) external returns (bool success) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance"); // 发送地址必须有足够的代币余额
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool success) {
        require(balanceOf[from] >= amount, "Insufficient balance"); // 发送地址必须有足够的代币余额
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded"); // 需要检查授权限制
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount; // 更新允许转移的代币数量
        emit Transfer(from, to, amount);
        return true;
    }
}