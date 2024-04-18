/**
 *Submitted for verification at Arbiscan.io on 2024-04-18
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT
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
library StringUtils {
    function strLen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
        bytes1 b = bytes(s)[i];
        if (b < 0x80) {
            i += 1;
        } else if (b < 0xE0) {
            i += 2;
        } else if (b < 0xF0) {
            i += 3;
        } else if (b < 0xF8) {
            i += 4;
        } else if (b < 0xFC) {
            i += 5;
        } else {
            i += 6;
        }
        }
        return len;
    }
    function toLower(string memory s) internal pure returns (string memory) {
        bytes memory _bytes = bytes(s);
        for (uint i = 0; i < _bytes.length; i++) {
        if (uint8(_bytes[i]) >= 65 && uint8(_bytes[i]) <= 90) {
            _bytes[i] = bytes1(uint8(_bytes[i]) + 32);
        }
        }
        return string(_bytes);
    }
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
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
interface IERC20Metadata is IERC20 {
     function name() external view returns (string memory);
     function symbol() external view returns (string memory);
     function decimals() external view returns (uint8);
}
interface OpenRunesPair {
    function selltoken(address user , uint tokenamount) external ;
}
contract OpenRunesToken is IERC20 , IERC20Metadata{
    
    using SafeMath for uint;
    mapping(address => bool) private iswhite;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    bool cantransfer;
    address pair;
    address factory;

    constructor(
        uint supply,
		string memory tick
    ){
        _totalSupply = supply;
        _name = tick;
        _symbol = tick;
        factory = msg.sender;
        _balances[factory] = _totalSupply;
        iswhite[factory] = true;
        emit Transfer(address(0), factory, _totalSupply);
    }
    modifier onlyFactory() { 
		require(msg.sender == factory, "Only Factory"); 
		_; 
	}

    function name() public view virtual override returns (string memory) {
         return _name;
    }
    function symbol() public view virtual override returns (string memory) {
         return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
         return 18;
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[sender] >= amount,"exceed balance!");
        require(iswhite[sender] || iswhite[to] || cantransfer,"can not transfer");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[to] = _balances[to].add(amount);
        if(to == pair && sender != factory){
            OpenRunesPair(pair).selltoken(sender,amount);
        }
        emit Transfer(sender, to, amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function setpair(address _pair) external onlyFactory{
        pair = _pair;
        iswhite[_pair] = true;
    }
    function setwhite(address _user,bool _iswhite) external onlyFactory{
        iswhite[_user] = _iswhite;
    }
    function settransfer(bool _cantransfer) external onlyFactory{
        cantransfer = _cantransfer;
    }
}