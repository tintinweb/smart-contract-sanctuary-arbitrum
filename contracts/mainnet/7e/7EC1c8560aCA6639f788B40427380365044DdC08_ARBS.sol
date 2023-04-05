/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ARBS is ERC20Burnable, Ownable {
  using SafeMath for uint256;

  mapping(address => bool) public isExcludedFromFee;
  mapping(address => bool) public whiteListedPair;

  uint256 public immutable MAX_SUPPLY;
  uint256 public BUY_FEE = 0;
  uint256 public SELL_FEE = 450;
  uint256 public TREASURY_FEE = 50;

  bool public autoSwap = true;

  uint256 public totalBurned = 0;

  address payable public devAddress;
  IUniswapV2Router02 public uniswapV2Router;

  event TokenRecoverd(address indexed _user, uint256 _amount);
  event FeeUpdated(address indexed _user, uint256 _feeType, uint256 _fee);
  event ToggleV2Pair(address indexed _user, address indexed _pair, bool _flag);
  event AddressExcluded(address indexed _user, address indexed _account, bool _flag);
  event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

  constructor(
    uint256 _maxSupply,
    uint256 _initialSupply,
    address router_,
    address payable _dev
  ) public ERC20("ArbSwap", "ARBS") {
    require(_initialSupply <= _maxSupply, "ARBS: The _initialSupply should not exceed the _maxSupply");

    MAX_SUPPLY = _maxSupply;
    isExcludedFromFee[owner()] = true;
    isExcludedFromFee[address(this)] = true;
    isExcludedFromFee[devAddress] = true;
    devAddress = _dev;

    if (_initialSupply > 0) {
      _mint(_msgSender(), _initialSupply);
    }

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router_);

    // address uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
    //   .createPair(address(this), _uniswapV2Router.WETH());

    // whiteListedPair[uniswapV2Pair] = true;

    // emit ToggleV2Pair(_msgSender(), uniswapV2Pair, true);

    uniswapV2Router = _uniswapV2Router;
  }

  modifier onlyDev() {
    require(devAddress == _msgSender() || owner() == _msgSender(), "ARBS: You don't have the permission!");
    _;
  }

  /************************************************************************/

  // function setAutoSwap(bool _flag) external onlyDev {
  //   autoSwap = _flag;
  // }

  // /************************************************************************/

  // function swapTokensForEth(uint256 tokenAmount) internal {
  //   // generate the uniswap pair path of token -> weth
  //   address[] memory path = new address[](2);
  //   path[0] = address(this);
  //   path[1] = uniswapV2Router.WETH();

  //   _approve(address(this), address(uniswapV2Router), tokenAmount);
  //   // make the swap
  //   uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
  //     tokenAmount,
  //     0, // accept any amount of ETH
  //     path,
  //     devAddress,
  //     block.timestamp
  //   );
  // }

  /************************************************************************/

  function _burn(address account, uint256 amount) internal override {
    super._burn(account, amount);
    totalBurned = totalBurned.add(amount);
  }

  /************************************************************************/

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    uint256 burnFee;
    uint256 treasuryFee;

    if (whiteListedPair[sender]) {
      burnFee = BUY_FEE;
    } else if (whiteListedPair[recipient]) {
      burnFee = SELL_FEE;
      treasuryFee = TREASURY_FEE;
    }

    if (
      (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ||
      (!whiteListedPair[sender] && !whiteListedPair[recipient])
    ) {
      burnFee = 0;
      treasuryFee = 0;
    }

    uint256 burnFeeAmount = amount.mul(burnFee).div(10000);
    uint256 treasuryFeeAmount = amount.mul(treasuryFee).div(10000);

    if (burnFeeAmount > 0) {
      _burn(sender, burnFeeAmount);
      amount = amount.sub(burnFeeAmount);
      // amount = amount - burnFeeAmount;
    }

    if (treasuryFeeAmount > 0) {
      super._transfer(sender, devAddress, treasuryFeeAmount);

      amount = amount.sub(treasuryFeeAmount);
      // amount = amount - treasuryFeeAmount;
    }

    super._transfer(sender, recipient, amount);
  }

  /************************************************************************/

  function updateUniswapV2Router(address newAddress) public onlyDev {
    require(newAddress != address(uniswapV2Router), "ARBS: The router already has that address");
    emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    uniswapV2Router = IUniswapV2Router02(newAddress);
    // address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
    //   .createPair(address(this), uniswapV2Router.WETH());
  }


  /**************************************************************************/

  function excludeMultipleAccountsFromFees(address[] calldata _accounts, bool _excluded) external onlyDev {
    for (uint256 i = 0; i < _accounts.length; i++) {
      isExcludedFromFee[_accounts[i]] = _excluded;

      emit AddressExcluded(_msgSender(), _accounts[i], _excluded);
    }
  }

  function enableV2PairFee(address _account, bool _flag) external onlyDev {
    whiteListedPair[_account] = _flag;

    emit ToggleV2Pair(_msgSender(), _account, _flag);
  }

  function updateDevAddress(address payable _dev) external onlyDev {
    isExcludedFromFee[devAddress] = false;
    emit AddressExcluded(_msgSender(), devAddress, false);

    devAddress = _dev;
    isExcludedFromFee[devAddress] = true;

    emit AddressExcluded(_msgSender(), devAddress, true);
  }


  function recoverToken(address _token) external onlyDev {
    uint256 tokenBalance = IERC20(_token).balanceOf(address(this));

    require(tokenBalance > 0, "ARBS: The contract doen't have tokens to be recovered!");

    IERC20(_token).transfer(devAddress, tokenBalance);

    emit TokenRecoverd(devAddress, tokenBalance);
  }

  /***************************************************************************/
}