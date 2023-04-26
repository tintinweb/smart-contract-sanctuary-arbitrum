/**
 *Submitted for verification at Arbiscan on 2023-04-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.3 <0.9.0;


interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract PhanesNetwork is IERC20 {
    address public owner;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) public isExcludedFromMaxLimit;


    constructor() {
        symbol = "PHANES";
        name = "Phanes Network";
        decimals = 18;
        _totalSupply = 10000000 * 10**uint(decimals);
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        isExcludedFromMaxLimit[owner] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        if (!isExcludedFromMaxLimit[to] && !isExcludedFromMaxLimit[msg.sender]) {
            require(balances[to] <= (2 * _totalSupply) / 100, "Max token amount of sender/receiver cannot exceed 2% of total supply");
            require(balances[msg.sender] <= (2 * _totalSupply) / 100, "Max token amount of sender/receiver cannot exceed 2% of total supply");
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        if (!isExcludedFromMaxLimit[to] && !isExcludedFromMaxLimit[from]) {
            require(balances[to] <= (2 * _totalSupply) / 100, "Max token amount of sender/receiver cannot exceed 2% of total supply");
            require(balances[from] <= (2 * _totalSupply) / 100, "Max token amount of sender/receiver cannot exceed 2% of total supply");
        }
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Only owner can call this function.");
        owner = newOwner;
    }

    function excludeWalletFromMaxLimit(address _address, bool shouldExclude) external {
        require(msg.sender == owner, "Only owner can call this function.");
        isExcludedFromMaxLimit[_address] = shouldExclude;
    }
}