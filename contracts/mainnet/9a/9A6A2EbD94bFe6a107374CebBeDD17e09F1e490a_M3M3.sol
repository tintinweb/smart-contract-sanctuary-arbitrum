// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract M3M3 {
  string private _name = "M3M3";
  string private _symbol = "M3M3";
  uint256 private _totalSupply = 69_420_000_000_000 ether;
  uint8 private _decimals = 18;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  address public mktgAddress = 0x1e0e9AC6364d41FA98e5158918F8080f14ef7309;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor() {
    _balances[msg.sender] = _totalSupply;
  }

  function name() public view virtual returns (string memory) {
    return _name;
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view virtual returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual returns (uint256) {
    return _balances[account];
  }

  function allowance(address owner, address spender) public view virtual returns (uint256) {
    return _allowances[owner][spender];
  }

  function _transfer(address _from, address _to, uint256 _value) private {
    require(_from != address(0), "Transfer from the zero address");
    require(_to != address(0), "Transfer to the zero address");
    require(_value > 0, "Transfer value must be greater than zero");
    require(_balances[_from] >= _value, "Insufficient balance");

    uint256 tax = _value * 5 / 100;
    uint256 halfTax = tax / 2;
    uint256 amount = _value - tax;

    _balances[_from] -= _value;
    _balances[_to] += amount;
    _balances[mktgAddress] += halfTax;
    _totalSupply -= halfTax; // burn half of the tax

    emit Transfer(_from, _to, amount);
    emit Transfer(_from, mktgAddress, halfTax);
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _allowances[_from][msg.sender], "Insufficient allowance");
    _allowances[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0), "Approve to the zero address");
    _allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool success) {
    require(_spender != address(0), "Approve to the zero address");
    _allowances[msg.sender][_spender] += _addedValue;
    emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
    return true;
  }

  function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool success) {
    require(_spender != address(0), "Approve to the zero address");
    _allowances[msg.sender][_spender] -= _subtractedValue;
    emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
    return true;
  }
}