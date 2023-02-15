/**
 *Submitted for verification at Arbiscan on 2023-02-14
*/

/**
101 Tokens.

0 Tax.

No team tokens.

No private sale.

No presale.

Liquidity will be burned and ownership renounced.

Telegram: https://t.me/Arbitrum101
*/

pragma solidity 0.6.6;

contract Arb101 {
   
    mapping (address => uint256) public balanceOf;

    string public name = "Arb101";
    string public symbol = "101";
    uint8 public decimals = 18;
    uint256 public totalSupply = 101 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}