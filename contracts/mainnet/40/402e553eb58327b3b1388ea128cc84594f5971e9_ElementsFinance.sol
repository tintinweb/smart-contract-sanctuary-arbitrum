/**
 *Submitted for verification at Arbiscan on 2023-02-07
*/

/*

Welcome to Elements Finance.

Taxes:
  - 8% buys (decreasing every days)
  - 8% sells (decreasing every days)

Telegram: https://t.me/ElementsFinance
Website: https://elementsfinance.io/
Discord: https://discord.gg/elementsfinance
Twitter: https://twitter.com/Elements_Fi
Medium: https://medium.com/@Elements_Fi

*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

interface ERC20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender)
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

abstract contract Ownable {
  address internal owner;

  constructor(address _owner) {
    owner = _owner;
  }

  modifier onlyOwner() {
    require(isOwner(msg.sender), "!OWNER");
    _;
  }

  function isOwner(address account) public view returns (bool) {
    return account == owner;
  }

  function renounceOwnership() public onlyOwner {
    owner = address(0);
    emit OwnershipTransferred(address(0));
  }

  event OwnershipTransferred(address owner);
}

interface IDEXFactory {
  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IDEXRouter {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

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

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

contract ElementsFinance is ERC20, Ownable {
  using SafeMath for uint256;

  address routerAdress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
  address DEAD = 0x000000000000000000000000000000000000dEaD;

  string constant _name = "Elements Finance";
  string constant _symbol = "ELMT";
  uint8 constant _decimals = 18;

  uint256 public _totalSupply = 0;
  uint256 public maxTx = 1; // 1% of total supply
  uint256 public maxWallet = 1; // 1% of total supply

  mapping(address => uint256) _balances;
  mapping(address => mapping(address => uint256)) _allowances;

  mapping(address => bool) isFeeExempt;
  mapping(address => bool) isTxLimitExempt;

  uint256 liquidityFee = 4;
  uint256 marketingFee = 4;
  uint256 totalFee = liquidityFee + marketingFee;
  uint256 feeDenominator = 100;

  address public marketingFeeReceiver;
  address public deployer;

  address public teamAddress;
  address public treasuryAddress;
  address public partnershipAddress;
  address public swapperAddress;

  bool tokensDistributed = false;
  bool tradingEnabled = false;

  IDEXRouter public router;
  address public pair;

  bool public swapEnabled = true;
  uint256 public swapThreshold = 1; // 1% of total supply
  bool inSwap;
  modifier swapping() {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor() Ownable(msg.sender) {
    router = IDEXRouter(routerAdress);
    pair = IDEXFactory(router.factory()).createPair(
      router.WETH(),
      address(this)
    );
    _allowances[address(this)][address(router)] = type(uint256).max;

    address _owner = owner;
    isFeeExempt[msg.sender] = true;
    isTxLimitExempt[address(router)] = true;
    isTxLimitExempt[_owner] = true;
    isTxLimitExempt[msg.sender] = true;
    isTxLimitExempt[DEAD] = true;

    marketingFeeReceiver = msg.sender;
    deployer = msg.sender;
  }

  receive() external payable {}

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function decimals() external pure override returns (uint8) {
    return _decimals;
  }

  function symbol() external pure override returns (string memory) {
    return _symbol;
  }

  function name() external pure override returns (string memory) {
    return _name;
  }

  function getOwner() external view override returns (address) {
    return owner;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function allowance(address holder, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowances[holder][spender];
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function approveMax(address spender) external returns (bool) {
    return approve(spender, type(uint256).max);
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    return _transferFrom(msg.sender, recipient, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    if (_allowances[sender][msg.sender] != type(uint256).max) {
      _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(
        amount,
        "Insufficient Allowance"
      );
    }

    return _transferFrom(sender, recipient, amount);
  }

  function _transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    if (inSwap) {
      return _basicTransfer(sender, recipient, amount);
    }

    if (sender == deployer || recipient == deployer) {
      return _basicTransfer(sender, recipient, amount);
    } else {
      require(tradingEnabled, "Trading is not enabled yet.");
    }

    if (recipient != pair && recipient != DEAD) {
      require(
        isTxLimitExempt[recipient] ||
          _balances[recipient] + amount <= (maxWallet * _totalSupply) / 100,
        "Transfer amount exceeds the bag size."
      );
    }

    if (shouldSwapBack() && !isTxLimitExempt[recipient]) {
      swapBack();
    }

    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

    uint256 amountReceived = shouldTakeFee(sender)
      ? takeFee(sender, amount)
      : amount;
    _balances[recipient] = _balances[recipient].add(amountReceived);

    emit Transfer(sender, recipient, amountReceived);
    return true;
  }

  function distributeTokens(
    address _rewardsPool,
    address _treasury,
    address _team,
    address _lp
  ) public onlyOwner {
    require(!tokensDistributed, "only can distribute once");
    tokensDistributed = true;
    _totalSupply = 400_000 * (10**_decimals);
    _balances[_rewardsPool] = 300_000 * (10**_decimals);
    emit Transfer(address(0), _rewardsPool, 300_000 * (10**_decimals));
    _balances[_treasury] = 8000 * (10**_decimals);
    emit Transfer(address(0), _treasury, 8000 * (10**_decimals));
    _balances[_team] = 32_000 * (10**_decimals);
    emit Transfer(address(0), _team, 32_000 * (10**_decimals));
    _balances[_lp] = 60_000 * (10**_decimals);
    emit Transfer(address(0), _lp, 60_000 * (10**_decimals));
  }

  function setAddresses(
    address _teamAddress,
    address _treasuryAddress,
    address _partnershipAddress,
    address _swapperAddress
  ) external onlyOwner {
    teamAddress = _teamAddress;
    treasuryAddress = _treasuryAddress;
    partnershipAddress = _partnershipAddress;
    swapperAddress = _swapperAddress;
  }

  function _basicTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function shouldTakeFee(address sender) internal view returns (bool) {
    return !isFeeExempt[sender];
  }

  function takeFee(address sender, uint256 amount) internal returns (uint256) {
    uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
    _balances[address(this)] = _balances[address(this)].add(feeAmount);
    emit Transfer(sender, address(this), feeAmount);
    return amount.sub(feeAmount);
  }

  function shouldSwapBack() internal view returns (bool) {
    return
      msg.sender != pair &&
      !inSwap &&
      swapEnabled &&
      _balances[address(this)] >= (swapThreshold * _totalSupply) / 10000;
  }

  function swapBack() internal swapping {
    uint256 contractTokenBalance = (swapThreshold * _totalSupply) / 10000;
    uint256 amountToLiquify = contractTokenBalance
      .mul(liquidityFee)
      .div(totalFee)
      .div(2);
    uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = router.WETH();

    uint256 balanceBefore = address(this).balance;

    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );
    uint256 amountETH = address(this).balance.sub(balanceBefore);
    uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
    uint256 amountETHLiquidity = amountETH
      .mul(liquidityFee)
      .div(totalETHFee)
      .div(2);
    uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);

    (
      bool MarketingSuccess, /* bytes memory data */

    ) = payable(marketingFeeReceiver).call{
        value: amountETHMarketing,
        gas: 30000
      }("");
    require(MarketingSuccess, "receiver rejected ETH transfer");

    if (amountToLiquify > 0) {
      router.addLiquidityETH{value: amountETHLiquidity}(
        address(this),
        amountToLiquify,
        0,
        0,
        marketingFeeReceiver,
        block.timestamp
      );
      emit AutoLiquify(amountETHLiquidity, amountToLiquify);
    }
  }

  function buyTokens(uint256 amount, address to) internal swapping {
    address[] memory path = new address[](2);
    path[0] = router.WETH();
    path[1] = address(this);

    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
      0,
      path,
      to,
      block.timestamp
    );
  }

  function setMarketingFeeReceiver(address _marketingFeeReceiver) external {
    require(
      msg.sender == deployer,
      "Only deployer can set marketingFeeReceiver"
    );
    marketingFeeReceiver = _marketingFeeReceiver;
  }

  function clearStuckBalance() external {
    payable(marketingFeeReceiver).transfer(address(this).balance);
  }

  function setWalletLimit(uint256 amountPercent) external onlyOwner {
    maxWallet = amountPercent;
  }

  function setMaxTx(uint256 amountPercent) external onlyOwner {
    maxTx = amountPercent;
  }

  function enableTrading() external onlyOwner {
    tradingEnabled = true;
  }

  function setFee(uint256 _liquidityFee, uint256 _marketingFee)
    external
    onlyOwner
  {
    liquidityFee = _liquidityFee;
    marketingFee = _marketingFee;
    totalFee = liquidityFee + marketingFee;
  }

  event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}