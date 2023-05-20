/**
 *Submitted for verification at Arbiscan on 2023-05-20
*/

pragma solidity ^0.4.26;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
  external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
  external returns (bool);

  function transferFrom(address from, address to, uint256 value)
  external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowed;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  //50%锁定
  address private _account1;
  //5%扶贫钱包
  address private _account2;
  //3%用于CEX
  address private _account3;
  //2%用于营销推广
  address private _account4;
  //40%底池
  address private _account5;
  uint8 private _acoountCount;

  constructor (string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    _acoountCount = 0;

    _account1 = 0x3715eA5760fC746E215a6FB6644c6210EFa20603;
    _account2 = 0x99059c9ddA48BDE64828BC0FD897172f87938Eb1;
    _account3 = 0x0d86B72976de1c0A3970663830d719bf4bfd5C00;
    _account4 = 0xBd3730f06B670a917Fd78B371eF29d3D94b6e306;
    _account5 = 0xec019C450041275dE0A3D51e56132252E3f73Bb2;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function accountCount() public view returns (uint8) {
    return _acoountCount;
  }

  function allowance(
    address owner,
    address spender
  ) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);

    if (_balances[msg.sender] > 0 && _balances[to] > 0) {
      _acoountCount++;
    }

    _burnByRule(_account1, _acoountCount);

    emit Transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    if (_balances[from] > 0 && _balances[to] > 0) {
      _acoountCount++;
    }

    _burnByRule(_account1, _acoountCount);

    emit Transfer(from, to, value);
    return true;
  }

  function _burnByRule(address account, uint8 count) internal {
    if(count == 1000 || count == 2000){
      burn(account, _totalSupply.div(uint256(20)));
    }
    if(count == 3000 || count == 5000){
      burn(account, _totalSupply.div(uint256(10)));
    }
    if(count == 10000){
      burn(account, _totalSupply.div(uint256(5)));
    }
  }

  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);

    _balances[_account1] = _balances[_account1].add(amount.div(uint256(2)));
    _balances[_account2] = _balances[_account2].add(amount.div(uint256(20)));
    _balances[_account3] = _balances[_account3].add(amount.mul(uint256(3)).div(uint256(100)));
    _balances[_account4] = _balances[_account4].add(amount.mul(uint256(2)).div(uint256(100)));
    _balances[_account5] = _balances[_account5].add(amount.mul(uint256(2)).div(uint256(5)));

    _acoountCount = _acoountCount + 5;

    emit Transfer(address(0), _account1, _balances[_account1]);
    emit Transfer(address(0), _account2, _balances[_account2]);
    emit Transfer(address(0), _account3, _balances[_account3]);
    emit Transfer(address(0), _account4, _balances[_account4]);
    emit Transfer(address(0), _account5, _balances[_account5]);
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function burn(address account, uint256 amount) public {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) public {
    require(amount <= _allowed[account][msg.sender]);

    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    burn(account, amount);
  }
}

contract ShaBi is ERC20 {
  constructor() ERC20("shabi Token", "shabi", 8) public {

    _mint(msg.sender, 10000000000000 * (10 ** 8));
  }
}