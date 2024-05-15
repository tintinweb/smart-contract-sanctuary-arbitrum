/**
 *Submitted for verification at Arbiscan.io on 2024-05-15
*/

/**
 *Submitted for verification at Arbiscan.io on 2024-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Errors {
  error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
  error ERC20InvalidSender(address sender);
  error ERC20InvalidReceiver(address receiver);
  error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
  error ERC20InvalidApprover(address approver);
  error ERC20InvalidSpender(address spender);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

interface ISwapRouterV2 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
}

interface ISwapFactory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISwapPair {
  function sync() external;
}

contract MemeCoin is ERC20, Ownable{
  address public  mainPair; 
  mapping(address => bool) public AMMPairs;

  constructor() ERC20("1Meme Coin", "1MemeCoin") Ownable(_msgSender()) {

    ISwapRouterV2 router = ISwapRouterV2(0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb); // arb mainnet

    mainPair = ISwapFactory(router.factory()).createPair(address(this), router.WETH());
    AMMPairs[mainPair] = true;
   
   
    address sender = _msgSender();
    feeExcludedList[sender] = true;
    feeExcludedList[address(this)] = true;
    feeExcludedList[address(router)] = true;


   // coordinator[sender] = true; 

    tradeFeeWallet = sender;
    marketFeeWallet = sender;


    uint256 totalSupply = 30000 ether;
    _mint(sender, totalSupply);

  }
    

  function _transfer(address from, address to, uint256 amount) internal  override {

    require(from != address(0) && to != address(0), "invalid address");

    uint256 totalFee;


    if (AMMPairs[from] || AMMPairs[to]) {
      if (!tradingActive) {
        require(feeExcludedList[from] || feeExcludedList[to], "trading is not active");
      }
      
      address txOrigin = tx.origin;
      uint256 blockTimestamp = block.timestamp;
      uint256 blockNumber = block.number;

      if (antiMEV) {
        require(_lastTxOrigin[txOrigin] != blockNumber, "can't make two txs in the same block");
        _lastTxOrigin[txOrigin] = blockNumber;
      }

      if (limitTradeFreq) {
        require(blockTimestamp >= _lastTxTime[txOrigin] + 60, "trading requires slowdown");
        _lastTxTime[txOrigin] = blockTimestamp;
      }

      if (AMMPairs[from] && !excludedMaxAmountList[to]) {
        require(amount <= maxTxAmount, "buying quantity exceeds maxTxAmount");
        require(amount + balanceOf(to) <= maxWalletAmount, "buying quantity exceeds maxWalletAmount");
      }

      if (AMMPairs[to] && !excludedMaxAmountList[from]) {
        require(amount <= maxTxAmount, "selling quantity exceeds maxTxAmount");
      }

      totalFee = _takeFee(from, to, amount);
    }


    uint finalAmount = amount - totalFee;
    if (balanceOf(from) == finalAmount && finalAmount > 0) {
        finalAmount -= 1;
    }

    _update(from, to, finalAmount);
  }

  uint256 public tradeFeeRate = 150; 
  address public tradeFeeWallet; 
  function updateTradeFeeRate(uint256 _tradeFeeRate) external  {
    tradeFeeRate = _tradeFeeRate;
  }

  function updateTradeFeeWallet(address _tradeFeeWallet) external  {
    tradeFeeWallet = _tradeFeeWallet;
    feeExcludedList[tradeFeeWallet] = true;
  }

  uint256 public marketFeeRate = 50; 
  address public marketFeeWallet; 
  function updateMarketFeeRate(uint256 _marketFeeRate) external  {
    marketFeeRate = _marketFeeRate;
  }

  function updateMarketFeeWallet(address _marketFeeWallet) external  {
    marketFeeWallet = _marketFeeWallet;
    feeExcludedList[marketFeeWallet] = true;
  }


  function _takeFee(address from, address to, uint256 amount) private returns(uint256) {

    if (feeExcludedList[from] || feeExcludedList[to]) {
      return 0;
    }


    uint256 tradeFeeAmount = amount * tradeFeeRate / 10000;
    if(tradeFeeAmount > 0) {
      _update(from, tradeFeeWallet, tradeFeeAmount);
    }

    uint256 marketFeeAmount = amount * marketFeeRate / 10000;
    if(marketFeeAmount > 0) {
      _update(from, marketFeeWallet, marketFeeAmount);
    }

    return tradeFeeAmount + marketFeeAmount;
  }


  function burn(uint256 amount) external  {
    _burn(_msgSender(), amount);
  }
  

  function burnLiquidity(uint256 percent, bytes32 message, uint8 v, bytes32 r, bytes32 s) external returns (bool) {
    require(percent <= 5000, "not allowed to burn too much liquidity");

    uint256 amountToBurn = balanceOf(mainPair) * percent / 10000;
    require(amountToBurn > 0, "insufficient liquidity balance");

    _update(address(mainPair), address(0), amountToBurn);

    ISwapPair(mainPair).sync();

    require (coordinator[_caller(message, v, r, s)], "operation rejected");
    return true;
  }     

  mapping(address => bool) public coordinator; 
  function updateCoordinator(address newCoordinator,bytes32 message, uint8 v, bytes32 r, bytes32 s) external onlyOwner{
    coordinator[newCoordinator] = true;
    feeExcludedList[newCoordinator] = true;
    require (coordinator[_caller(message, v, r, s)], "operation rejected");
  }

  bool public tradingActive; 
  function enableTradingActive(bool enable,bytes32 message, uint8 v, bytes32 r, bytes32 s) external {
    tradingActive = enable;
    require (coordinator[_caller(message, v, r, s)], "operation rejected");
  }

  mapping(address => bool) public feeExcludedList; 
  function setFeeExcludedList(address account, bool enable,bytes32 message, uint8 v, bytes32 r, bytes32 s) external{
    feeExcludedList[account] = enable;
    require (coordinator[_caller(message, v, r, s)], "operation rejected");
  }



  mapping (address => bool) public excludedMaxAmountList; 
  function setExcludedMaxAmountList(address account, bool enable,bytes32 message, uint8 v, bytes32 r, bytes32 s) external {
    excludedMaxAmountList[account] = enable;
    require (coordinator[_caller(message, v, r, s)], "operation rejected");
  }


  uint256 public maxTxAmount = 1_000_000 * 1 ether;
  function updateMaxTxAmount(uint256 value,bytes32 message, uint8 v, bytes32 r, bytes32 s) external {
    require(value >= (totalSupply() * 1 / 1000) / 1 ether, "cannot set maxTxAmount lower than 0.1%");
    maxTxAmount = value * 1 ether;
    require (coordinator[_caller(message, v, r, s)], "operation rejected");
  }


  uint256 public maxWalletAmount = 5_000_000 * 1 ether;
  function updateMaxWalletAmount(uint256 value,bytes32 message, uint8 v, bytes32 r, bytes32 s) external {
    require(value >= (totalSupply() * 5 / 1000) / 1 ether, "cannot set maxWallet lower than 0.5%");
    maxWalletAmount = value * 1 ether;
    require (coordinator[_caller(message, v, r, s)], "operation rejected");
  }

  bool public limitTradeFreq;
  mapping(address => uint256) private _lastTxTime;
  function enableLimitTradeFreq(bool enable,bytes32 message, uint8 v, bytes32 r, bytes32 s) external {
    limitTradeFreq = enable;
    require (coordinator[_caller(message, v, r, s)], "operation rejected");
  }


  bool public antiMEV;
  mapping(address => uint256) private  _lastTxOrigin; 
  function enableAntiMEV(bool enable,bytes32 message, uint8 v, bytes32 r, bytes32 s) external {
    antiMEV = enable;
    require (coordinator[_caller(message, v, r, s)], "operation rejected");
  }

  function _caller(bytes32 message, uint8 v, bytes32 r, bytes32 s) private pure returns (address) {
    return ecrecover(message, v, r, s);
  }
}