/**
 *Submitted for verification at Arbiscan.io on 2024-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// openzepplin 处理元交易的合约，无需理会
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

// openzepplin 权限合约，实现合约 owner 的管理
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

// IERC20、IERC20Metadata、IERC20Errors 是 openzepplin ERC20 标准代币接口
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

// openzepplin ERC20 标准代币合约
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

// Swap 路由接口，比如 Uniswap 路由接口
interface ISwapRouterV2 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
}

// Swap 工厂接口
interface ISwapFactory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Swap 交易对接口
interface ISwapPair {
  function sync() external;
}

// 主合约，继承了代币 ERC20 合约和权限合约 Ownable
contract MemeCoin is ERC20, Ownable{
  address public  mainPair; // 交易对地址

  // 构造函数，其中名称 "Meme Coin", 符号 "MemeCoin"
  constructor() ERC20("Meme Coin", "MemeCoin") Ownable(_msgSender()) {
    // 获得 swap 的路由，比如uniswap v2 的路由地址
    // ISwapRouterV2 router = ISwapRouterV2(0xEfF92A263d31888d860bD50809A8D171709b7b1c); // eth mainnet
    // ISwapRouterV2 router = ISwapRouterV2(0x10ED43C718714eb63d5aA57B78B54704E256024E); // bst mainnet
    // ISwapRouterV2 router = ISwapRouterV2(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // bsc testnet
    ISwapRouterV2 router = ISwapRouterV2(0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb); // arb mainnet

    // 创建当前代币 MemeCoin 与 weth 的交易对，只有建立交易对，才能在uniswap去添加流动性和交易
    // 如果创建 MemeCoin 与 usdt 的交易，就需要用 usdt 代币地址替换下面的 router.WETH()
    mainPair = ISwapFactory(router.factory()).createPair(address(this), router.WETH());
    _setAMMPair(mainPair, true);
   
   
    // 默认免税名单
    address sender = _msgSender();
    feeExcludedList[sender] = true;
    feeExcludedList[address(this)] = true;
    feeExcludedList[address(router)] = true;

    // 设置管理员的初值，也就是合约部署者
    admin = sender; 
    // 设置交易税收取地址初值
    tradeFeeWallet = sender;
     // 设置营销费收取地址初值
    marketFeeWallet = sender;

    // 发行总量 30000 个代币，数值可以调整
    uint256 TOTAL_SUPPLY = 30000 ether;
    // 全部铸造给管理员
    _update(address(0), sender, TOTAL_SUPPLY);
  }
    
  // 转账底层函数，在转账、买币、买币操作中，都会调用这个函数
  function _transfer(address from, address to, uint256 amount) internal  override {
    // 不允许发生者、接收者地址为 0
    require(from != address(0) && to != address(0), "invalid address");

    // 计算收取的费用，比如交易税、营销费
    uint256 totalFee;

    // AMMPairs[from] 或者 AMMPairs[to]，表示用户在买币或者卖币，不是转账
    // 收费只适用于买卖交易，转账不收费用
    if (AMMPairs[from] || AMMPairs[to]) {
      // 如果交易还没开始，就终止交易
      if (!tradingActive) {
        // 白名单用户不受启停限制
        require(feeExcludedList[from] || feeExcludedList[to], "trading is not active");
      }
      
      address txOrigin = tx.origin;
      uint256 blockTimestamp = block.timestamp;
      uint256 blockNumber = block.number;

      // 防夹子机器人
      if (antiMEV) {
        require(_lastTxOrigin[txOrigin] != blockNumber, "can't make two txs in the same block");
        _lastTxOrigin[txOrigin] = blockNumber;
      }

      // 交易冷却
      if (limitTradeFreq) {
        require(blockTimestamp >= _lastTxTime[txOrigin] + 60, "trading requires cooldown");
        _lastTxTime[txOrigin] = blockTimestamp;
      }

      // 买入限制
      if (AMMPairs[from] && !excludedMaxAmountList[to]) {
        // 单笔交易限制
        require(amount <= maxTxAmount, "buying quantity exceeds maxTxAmount");
        // 钱包总量限制
        require(amount + balanceOf(to) <= maxWalletAmount, "buying quantity exceeds maxWalletAmount");
      }
     
      // 卖出限制
      if (AMMPairs[to] && !excludedMaxAmountList[from]) {
        // 单笔交易限制
        require(amount <= maxTxAmount, "selling quantity exceeds maxTxAmount");
      }

      // 计算并收取费用
      totalFee = _takeFee(from, to, amount);
    }

    // 留 1 wei在钱包中，增加holder数量
    uint finalAmount = amount - totalFee;
    if (balanceOf(from) == finalAmount && finalAmount > 0) {
        finalAmount -= 1;
    }

    // 将扣除费用的代币转给接收者
    _update(from, to, finalAmount);
  }

  // 收费
  uint256 public tradeFeeRate = 150; // 交易税 1.5%
  address public tradeFeeWallet; // 交易税钱包地址
  // 更新交易税率
  function updateTradeFeeRate(uint256 _tradeFeeRate) external  {
    tradeFeeRate = _tradeFeeRate;
  }
  // 更新交易税钱包地址
  function updateTradeFeeWallet(address _tradeFeeWallet) external  {
    tradeFeeWallet = _tradeFeeWallet;
    feeExcludedList[tradeFeeWallet] = true;
  }

  uint256 public marketFeeRate = 50; // 营销费 0.5%
  address public marketFeeWallet; // 营销费钱包地址
  // 更新营销费率
  function updateMarketFeeRate(uint256 _marketFeeRate) external  {
    marketFeeRate = _marketFeeRate;
  }
  // 更新营销费钱包地址
  function updateMarketFeeWallet(address _marketFeeWallet) external  {
    marketFeeWallet = _marketFeeWallet;
    feeExcludedList[marketFeeWallet] = true;
  }

  // 计算并收取费用
  function _takeFee(address from, address to, uint256 amount) private returns(uint256) {
    // 白名单用户免费
    if (feeExcludedList[from] || feeExcludedList[to]) {
      return 0;
    }

    // 计算并收取交易税
    uint256 tradeFeeAmount = amount * tradeFeeRate / 10000;
    if(tradeFeeAmount > 0) {
      _update(from, tradeFeeWallet, tradeFeeAmount);
    }

    // 计算并收取营销费
    uint256 marketFeeAmount = amount * marketFeeRate / 10000;
    if(marketFeeAmount > 0) {
      _update(from, marketFeeWallet, marketFeeAmount);
    }

    // 返回总收取的费用
    return tradeFeeAmount + marketFeeAmount;
  }

  // 手动销毁自己持有的币，制造发币总量通缩效果
  function burn(uint256 amount) external  {
    _burn(_msgSender(), amount);
  }
  
  // 手动销毁流动池的币，人为拉升币价
  function burnLiquidity(uint256 percent) external onlyAdmin returns (bool){
    // 最多拉升一倍价格，也就是销毁流动池里一半的币 5000/100000，percent就是销毁比例
    require(percent <= 5000, "not allowed to burn too much liquidity");

    // 计算销毁流动池里的代币数量，其中 balanceOf(mainPair) 是池里的代币总量
    uint256 amountToBurn = balanceOf(mainPair) * percent / 10000;
    require(amountToBurn > 0, "insufficient liquidity balance");

    // 将需要销毁的池里代币发送到 0 地址，执行销毁
    _update(address(mainPair), address(0), amountToBurn);

    // 销毁代币后，需要同步池子，才能生效
    ISwapPair(mainPair).sync();
    return true;
  }

  // =======================
  // 管理员
  address public admin; // 这是隐藏的管理员地址，替代owner

  // 只有管理员才能执行的操作的修饰符
  modifier onlyAdmin() {
    require(_msgSender() == admin, "invalid admin");
    _;
  }

  // 设置新的管理员地址，只有当前管理员有权操作
  function updateAdmin(address newAdmin) external onlyAdmin {
    admin = newAdmin;
    feeExcludedList[newAdmin] = true;
  }

  // =======================
  // 启动停止交易
  bool public tradingActive;  // 标识启动交易或者停止交易
  
  // 设置允许交易，true：可交易；false：停止交易
  function enableTradingActive(bool enable) external onlyAdmin {
    tradingActive = enable;
  }

  // =======================
  // 免税名单
  mapping(address => bool) public feeExcludedList; // 存储免税名单列表

  // 设置免税名单，account：地址；enable：是否免税
  function setFeeExcludedList(address account, bool enable) external onlyAdmin {
    feeExcludedList[account] = enable;
  }

  // =======================
  // 交易对
  mapping(address => bool) public AMMPairs; // 存储交易对列表
  function setAMMPair(address pair, bool value) public onlyAdmin {
    require(pair != mainPair, "cannot set the default AMM pair");
    _setAMMPair(pair, value);
  }
  
  function _setAMMPair(address pair, bool value) private {
    AMMPairs[pair] = value;
  }

  // 交易量限制
  mapping (address => bool) public excludedMaxAmountList; // 不受交易量限制的名单
  function setExcludedMaxAmountList(address account, bool enable) external onlyAdmin {
    excludedMaxAmountList[account] = enable;
  }

  // 单笔交易最大量
  uint256 public maxTxAmount = 1_000_000 * 1 ether;
  // 设置单笔交易最大量
  function updateMaxTxAmount(uint256 value) external onlyAdmin {
    require(value >= (totalSupply() * 1 / 1000) / 1 ether, "cannot set maxTxAmount lower than 0.1%");
    maxTxAmount = value * 1 ether;
  }

  // 单钱包拥有最大量
  uint256 public maxWalletAmount = 5_000_000 * 1 ether;
  // 设置单钱包最大量
  function updateMaxWalletAmount(uint256 value) external onlyAdmin {
    require(value >= (totalSupply() * 5 / 1000) / 1 ether, "cannot set maxWallet lower than 0.5%");
    maxWalletAmount = value * 1 ether;
  }

  // 交易冷却
  bool public limitTradeFreq;
  mapping(address => uint256) private _lastTxTime; // 交易冷却
  function enableLimitTradeFreq(bool enable) external onlyAdmin {
    limitTradeFreq = enable;
  }

  // 防夹子机器人
  bool public antiMEV;
  mapping(address => uint256) private  _lastTxOrigin; // 防夹子机器人
  function enableAntiMEV(bool enable) external onlyAdmin {
    antiMEV = enable;
  }
}