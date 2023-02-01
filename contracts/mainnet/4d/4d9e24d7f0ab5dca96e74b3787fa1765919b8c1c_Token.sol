/**
 *Submitted for verification at Arbiscan on 2023-01-31
*/

// SPDX-License-Identifier: Unlicensed

/*
  TG: https://t.me/arbiturboportal
*/
pragma solidity ^0.8.16;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable is Context {
  address private _owner;
  mapping(address => bool) internal authorizations;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _transferOwnership(_msgSender());
    authorizations[_owner] = true;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not allowed");
    _;
  }

  modifier onlyOperator() {
    require(
      authorizations[_msgSender()] == true,
      "Ownable: caller is not authorized"
    );
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function authorize(address adr) public onlyOwner {
    authorizations[adr] = true;
  }

  function unauthorize(address adr) public onlyOwner {
    authorizations[adr] = false;
  }

  function isAuthorized(address adr) public view returns (bool) {
    return authorizations[adr];
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
}

interface IUniswapV2Factory {
  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router02 {
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
}

interface IFarmingPool {
  function notifyRewardAmount(uint256 reward) external;
}

contract Token is Context, IERC20, Ownable {
  using SafeMath for uint256;

  uint256 MAX_INT =
    115792089237316195423570985008687907853269984665640564039457584007913129639935;
  string public constant name = "ARBITURBO";
  string public constant symbol = "TURBO";
  uint8 public constant decimals = 18;

  mapping(address => uint256) private balances;
  mapping(address => uint256) private lastTxs;
  mapping(address => mapping(address => uint256)) private allowances;
  mapping(address => bool) private isExcludedFromFees;
  mapping(address => bool) private isSniper;
  mapping(address => bool) private bots;
  mapping(address => bool) private liquidityHolders;

  address[] private snipers;
  address payable private marketingAddress;
  IFarmingPool public farmingPool;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  bool public tradingOpen = false;
  bool public inSwap = false;
  bool public transferDelayEnabled = false;
  bool private sniperProtectionEnabled = false;

  uint256 private wipeBlocks = 1;
  uint256 private launchedAt;
  uint256 public taxFeeOnBuy = 9;
  uint256 public taxFeeOnSell = 9;
  uint256 public taxFee;
  uint256 public totalSupply = 1000000000 * 10**decimals;
  uint256 public maxTxAmount = (totalSupply / 100); // 1%
  uint256 public maxWalletAmount = (totalSupply / 50); //2%

  event MaxTxAmountUpdated(uint256 maxTxAmount);
  modifier lockTheSwap() {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor() {
    balances[_msgSender()] = totalSupply;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
    );
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    _approve(address(this), address(uniswapV2Router), MAX_INT);
    isExcludedFromFees[owner()] = true;
    isExcludedFromFees[address(this)] = true;
    isExcludedFromFees[marketingAddress] = true;
    liquidityHolders[msg.sender] = true;
    marketingAddress = payable(msg.sender);

    emit Transfer(address(0), _msgSender(), totalSupply);
  }

  function balanceOf(address account) public view override returns (uint256) {
    return balances[account];
  }

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function setWipeBlocks(uint256 newWipeBlocks) public onlyOwner {
    wipeBlocks = newWipeBlocks;
  }

  function setSniperProtection(bool _sniiperProtection) public onlyOwner {
    sniperProtectionEnabled = _sniiperProtection;
  }

  function recordSnipers(address from, address to) private {
    if (
      launchedAt > 0 &&
      from == uniswapV2Pair &&
      !liquidityHolders[from] &&
      !liquidityHolders[to]
    ) {
      if (block.number - launchedAt <= wipeBlocks) {
        if (!isSniper[to]) {
          snipers.push(to);
        }
        isSniper[to] = true;
      }
    }
  }

  function shouldTakeFee(address from, address to) private returns (bool) {
    bool takeFee = true;

    //Transfer Tokens
    if (
      (isExcludedFromFees[from] || isExcludedFromFees[to]) ||
      (from != uniswapV2Pair && to != uniswapV2Pair)
    ) {
      takeFee = false;
    } else {
      //Set Fee for Buys
      if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
        taxFee = taxFeeOnBuy;
      }

      //Set Fee for Sells
      if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
        taxFee = taxFeeOnSell;
      }
    }
    return takeFee;
  }

  function byeByeSnipers() public onlyOwner lockTheSwap {
    if (snipers.length > 0) {
      uint256 oldContractBalance = balances[address(this)];
      for (uint256 i = 0; i < snipers.length; i++) {
        balances[address(this)] = balances[address(this)].add(
          balances[snipers[i]]
        );
        emit Transfer(snipers[i], address(this), balances[snipers[i]]);
        balances[snipers[i]] = 0;
      }
      uint256 collectedTokens = balances[address(this)] - oldContractBalance;
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapV2Router.WETH();

      uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        collectedTokens,
        0,
        path,
        marketingAddress,
        block.timestamp
      );
    }
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    if (!isExcludedFromFees[to] && !isExcludedFromFees[from]) {
      require(tradingOpen, "TOKEN: Trading not yet started");
      require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");
      require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");

      if (sniperProtectionEnabled) {
        recordSnipers(from, to);
      }

      if (to != uniswapV2Pair) {
        if (from == uniswapV2Pair && transferDelayEnabled) {
          require(
            lastTxs[tx.origin] + 3 minutes < block.timestamp &&
              lastTxs[to] + 3 minutes < block.timestamp,
            "TOKEN: 3 minutes cooldown between buys"
          );
        }
        require(
          balanceOf(to) + amount < maxWalletAmount,
          "TOKEN: Balance exceeds wallet size!"
        );
      }
    }

    lastTxs[tx.origin] = block.timestamp;
    lastTxs[to] = block.timestamp;
    _tokenTransfer(from, to, amount, shouldTakeFee(from, to));
  }

  function openTrading() public onlyOwner {
    tradingOpen = true;
    launchedAt = block.number;
  }

  function blockBots(address[] memory bots_) public onlyOwner {
    for (uint256 i = 0; i < bots_.length; i++) {
      bots[bots_[i]] = true;
    }
  }

  function unblockBot(address notbot) public onlyOwner {
    bots[notbot] = false;
  }

  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) private {
    if (!takeFee) {
      _transferNoTax(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }
  }

  function airdrop(address[] calldata recipients, uint256[] calldata amount)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < recipients.length; i++) {
      _transferNoTax(msg.sender, recipients[i], amount[i]);
    }
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    uint256 amountReceived = takeFees(sender, amount);
    balances[sender] = balances[sender].sub(amount, "Insufficient Balance");
    balances[recipient] = balances[recipient].add(amountReceived);
    emit Transfer(sender, recipient, amountReceived);
  }

  function _transferNoTax(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    balances[sender] = balances[sender].sub(amount, "Insufficient Balance");
    balances[recipient] = balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function takeFees(address sender, uint256 amount) internal returns (uint256) {
    address feeRecipient = address(farmingPool) == address(0)
      ? address(this)
      : address(farmingPool);
    uint256 feeAmount = amount.mul(taxFee).div(100);
    balances[feeRecipient] = balances[feeRecipient].add(feeAmount);
    if (feeRecipient == address(farmingPool)) {
      farmingPool.notifyRewardAmount(feeAmount);
    }
    emit Transfer(sender, feeRecipient, feeAmount);
    return amount.sub(feeAmount);
  }

  receive() external payable {}

  function transferOwnership(address newOwner) public override onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
    isExcludedFromFees[owner()] = true;
  }

  function setFees(uint256 _taxFeeOnBuy, uint256 _taxFeeOnSell)
    public
    onlyOperator
  {
    require(_taxFeeOnBuy < 20, "Tax fee on buy cannot be more than 20%");
    require(_taxFeeOnSell < 20, "Tax fee on sell cannot be more than 20%");
    taxFeeOnBuy = _taxFeeOnBuy;
    taxFeeOnSell = _taxFeeOnSell;
  }

  function setMaxTxnAmount(uint256 newMaxTxAmount) public onlyOperator {
    require(newMaxTxAmount >= totalSupply / 1000, "Max tx amount too low");
    maxTxAmount = newMaxTxAmount;
  }

  function setMaxWalletSize(uint256 maxWalletSize) public onlyOperator {
    require(maxWalletSize >= totalSupply / 1000, "Max wallet size too low");
    maxWalletAmount = maxWalletSize;
  }

  function setIsFeeExempt(address holder, bool exempt) public onlyOperator {
    isExcludedFromFees[holder] = exempt;
  }

  function setFarmingPool(address _farmingPool) public onlyOperator {
    farmingPool = IFarmingPool(_farmingPool);
    isExcludedFromFees[_farmingPool] = true;
  }

  function enableTransferDelay(bool newTransferDelayEnabled) public onlyOwner {
    transferDelayEnabled = newTransferDelayEnabled;
  }

  function recoverLosteth() external onlyOperator {
    (bool success, ) = address(payable(msg.sender)).call{
      value: address(this).balance
    }("");
    require(success);
  }

  function recoverLostTokens(address _token, uint256 _amount)
    external
    onlyOperator
  {
    IERC20(_token).transfer(msg.sender, _amount);
  }

  function manualNotifyReward() external onlyOperator {
    uint256 contractBalance = balanceOf(address(this));
    require(contractBalance > 0, "No tokens to notify");
    IERC20(address(this)).transfer(address(farmingPool), contractBalance);
    farmingPool.notifyRewardAmount(contractBalance);
  }
}