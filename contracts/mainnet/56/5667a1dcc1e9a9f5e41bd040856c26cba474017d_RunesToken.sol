/**
 *Submitted for verification at Arbiscan.io on 2024-04-16
*/

pragma solidity 0.8.6;
// SPDX-License-Identifier: MIT
interface IERC20 {

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
      uint c = a + b;
      require(c >= a, "SafeMath: addition overflow");
      return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
      return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
      require(b <= a, errorMessage);
      uint c = a - b;
      return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
      if (a == 0) {
        return 0;
      }
      uint c = a * b;
      require(c / a == b, "SafeMath: multiplication overflow");
      return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
      return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
      // Solidity only automatically asserts when dividing by 0
      require(b > 0, errorMessage);
      uint c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold
      return c;
    }
    function mod(uint a, uint b) internal pure returns (uint) {
      return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
      require(b != 0, errorMessage);
      return a % b;
    }
}
contract RunesToken is IERC20{

    using SafeMath for uint;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping (address => bool) public isWhite;

    string private _symbol = "Runes";
    string private _name = "Runes Token";

    uint private constant E18 = 1000000000000000000;
    uint private _totalSupply = 10000000000 * E18;
    uint private _decimals = 18;

    address _owner;
    bool cantransfer;

    constructor(){

        _owner = msg.sender;
        isWhite[_owner] = true;
        
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);

    }

    function decimals() public view  returns(uint) {
        return _decimals;
    }
    function symbol() public view  returns (string memory) {
        return _symbol;
    }
    function name() public view  returns (string memory) {
        return _name;
    }
    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public override view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address to, uint amount) internal {

        require(isWhite[sender] || isWhite[to] || cantransfer,"can not transfer now");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[sender] >= amount,"exceed balance!");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(sender, to, amount); 

    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function setcantransfer(bool _cantransfer) external {
        require(msg.sender == _owner,"not owner");
        cantransfer = _cantransfer;
    }
    function setwhite(address _user,bool _iswhite) external {
        require(msg.sender == _owner,"not owner");
        isWhite[_user] = _iswhite;
    }
    function renounceOwnership() external {
        require(msg.sender == _owner,"not owner");
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
}