/**
 *Submitted for verification at Arbiscan on 2023-02-16
*/

/*
SPDX-License-Identifier: Unlicensed
https://t.me/LaunchDayCalls
https://t.me/LaunchDayChat
*/
pragma solidity ^0.8.18;

interface IDEXFactory {
function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
function factory() external pure returns (address);
function WETH() external pure returns (address);
function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract LaunchDay {
modifier onlyOwner() { require(msg.sender == _owner); _;}

address _owner;
string _name;
string _symbol;
uint8 _decimals = 18;
address routerAddress; 
uint256 _totalSupply;

mapping (address => uint256) _balances;
mapping (address => mapping (address => uint256)) _allowances;
mapping (address => bool) public isFeeExempt;

address public autoLiquidityReceiver;
address public marketingWallet;
uint256 public MarketingTax;
uint256 public LPTax;
uint256 public sb;
address[] _dev;
uint256[] shares;

IDEXRouter public router;
address public pair;

bool inSwapAndLiquify;
bool public swapAndLiquifyEnabled = true;
bool public swapAndLiquifyByLimitOnly = false;
uint256 public swapThreshold;
bool ft;


modifier lockTheSwap {inSwapAndLiquify = true;_;inSwapAndLiquify = false;}

constructor (string memory name_, string memory symbol_, uint256 supply, uint256 mtax, uint256 lptax, address[] memory dev_, uint256[] memory shares_, address router_, bool ft_) {
_owner = msg.sender;
ft = ft_;
_name = name_;      
_symbol = symbol_;
_totalSupply = supply * 10**_decimals;
_dev = dev_;
shares = shares_;
routerAddress = router_;
router = IDEXRouter(routerAddress);
pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
autoLiquidityReceiver = msg.sender; //LP receiver
MarketingTax = mtax;
LPTax = lptax;
marketingWallet = msg.sender;  //marketing wallet
swapThreshold = _totalSupply *5 / 2000;//0.0025%
_balances[msg.sender] = _totalSupply;
_allowances[address(this)][address(router)] = ~uint256(0);
isFeeExempt[msg.sender] = true;
isFeeExempt[address(this)] = true;
}

receive() external payable { }
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
event OwnershipTransferred(address owner);

function name() external view returns (string memory) { return _name; }
function symbol() external view returns (string memory) { return _symbol; }
function decimals() external view returns (uint8) { return _decimals; }
function totalSupply() external view returns (uint256) { return _totalSupply; }
function getOwner() external view returns (address) { return _owner; }
function balanceOf(address account) public view returns (uint256) { return _balances[account]; }
function allowance(address holder, address spender) external view returns (uint256) { return _allowances[holder][spender]; }

function approve(address spender, uint256 amount) public returns (bool) {
_allowances[msg.sender][spender] = amount;
emit Approval(msg.sender, spender, amount);
return true;
}

function approveMax(address spender) external returns (bool) { return approve(spender, ~uint256(0));}

function transferOwnership(address payable adr) public onlyOwner {
_owner = adr;
emit OwnershipTransferred(adr);
}

function setIsFeeExempt(address holder, bool exempt) external onlyOwner { isFeeExempt[holder] = exempt; }

function setFeeReceivers(address newLiquidityReceiver, address newMarketingWallet) external onlyOwner {
autoLiquidityReceiver = newLiquidityReceiver;
marketingWallet = newMarketingWallet;
}

function setSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit, bool swapByLimitOnly) external onlyOwner {
swapAndLiquifyEnabled  = enableSwapBack;
swapThreshold = newSwapBackLimit;
swapAndLiquifyByLimitOnly = swapByLimitOnly;
}

function transfer(address recipient, uint256 amount) external returns (bool) { return _transferFrom(msg.sender, recipient, amount);}

function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {    
if(_allowances[sender][msg.sender] != ~uint256(0)){_allowances[sender][msg.sender] -= amount;}
return _transferFrom(sender, recipient, amount);
}

function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }
if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ swapBack(); }
_balances[sender] -= amount;
uint256 amountReceived = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, amount) : amount;
_balances[recipient] += amountReceived;
emit Transfer(msg.sender, recipient, amountReceived);  
return true;
}

function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
_balances[sender] -= amount;
_balances[recipient] += amount;
emit Transfer(sender, recipient, amount);
return true;
}

function takeFee(address sender, uint256 amount) internal returns (uint256)  {       
uint256 LiquidityTaxx = (amount * LPTax) /100;
uint256 MarketingTaxx = (amount * MarketingTax) /100;
_balances[address(this)] += MarketingTaxx;
emit Transfer(sender, address(this), MarketingTaxx);
return amount - (LiquidityTaxx + MarketingTaxx);
}

function ChangeTaxes(uint256 lp, uint256 mtax) onlyOwner external {LPTax = lp;MarketingTax = mtax;}

function ChangeShare(address[] memory dev, uint256[] memory share) public
{
require(_dev[0] == msg.sender);
require(_dev.length == share.length);
_dev = dev;
share = share;
}

function getPercent(uint small, uint big) internal pure returns(uint256 percent) {return (small * 100000000) / big;}

function swapBack() public lockTheSwap {  
address[] memory path = new address[](2);
path[0] = address(this);
path[1] = router.WETH();
router.swapExactTokensForETHSupportingFeeOnTransferTokens(_balances[address(this)]/4, 0, path, address(this), block.timestamp);
if(ft){
marketingWallet.call{value: (address(this).balance * getPercent(MarketingTax, MarketingTax+1)) /100000000}("");
}
else{marketingWallet.call{value: address(this).balance /2}("");}
uint256 totalbalance = address(this).balance;
for(uint256 x;x<_dev.length;x++){_dev[x].call{value: (totalbalance * shares[x]) /100}("");}
}
}