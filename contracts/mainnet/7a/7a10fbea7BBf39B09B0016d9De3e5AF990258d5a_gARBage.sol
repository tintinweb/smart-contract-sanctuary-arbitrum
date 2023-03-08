/**
 *Submitted for verification at Arbiscan on 2023-03-08
*/

/**
SPDX-License-Identifier: Unlicensed
            /$$$$$$  /$$$$$$$  /$$$$$$$                               
           /$$__  $$| $$__  $$| $$__  $$                              
  /$$$$$$ | $$  \ $$| $$  \ $$| $$  \ $$  /$$$$$$   /$$$$$$   /$$$$$$ 
 /$$__  $$| $$$$$$$$| $$$$$$$/| $$$$$$$  |____  $$ /$$__  $$ /$$__  $$
| $$  \ $$| $$__  $$| $$__  $$| $$__  $$  /$$$$$$$| $$  \ $$| $$$$$$$$
| $$  | $$| $$  | $$| $$  \ $$| $$  \ $$ /$$__  $$| $$  | $$| $$_____/
|  $$$$$$$| $$  | $$| $$  | $$| $$$$$$$/|  $$$$$$$|  $$$$$$$|  $$$$$$$
 \____  $$|__/  |__/|__/  |__/|_______/  \_______/ \____  $$ \_______/
 /$$  \ $$                                         /$$  \ $$          
|  $$$$$$/                                        |  $$$$$$/          
 \______/                                          \______/           
https://t.me/gARBageitrum
Liquidity Tax; 4%
Marketing Tax; 3%
Max Wallet   ; 2%
*/
pragma solidity ^0.8.18;

interface IDEXFactory {
function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
function factory() external pure returns (address);
function WETH() external pure returns (address);
function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract gARBage {
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
mapping (address => bool) public isMaxWalletExempt;

uint256 public MarketingTax;
uint256 public LPTax;
address[] _dev;
uint256[] shares;

IDEXRouter public router;
address public pair;

bool inSwapAndLiquify;
bool public swapAndLiquifyEnabled = true;
bool public swapAndLiquifyByLimitOnly;
uint256 public swapThreshold;
uint256 public maxwallet;

modifier lockTheSwap {inSwapAndLiquify = true;_;inSwapAndLiquify = false;}

constructor (string memory name_, string memory symbol_, uint256 supply, uint256 mtax, uint256 lptax, address[] memory dev_, uint256[] memory shares_, address router_, uint256 MaxWallet_) {
_owner = msg.sender;
_name = name_;      
_symbol = symbol_;
_totalSupply = supply * 10**_decimals;
_dev = dev_;
shares = shares_;
routerAddress = router_;
MarketingTax = mtax;
LPTax = lptax;
router = IDEXRouter(routerAddress);
pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
swapThreshold = _totalSupply *5 / 2000;//0.0025%
_balances[msg.sender] = _totalSupply;
_allowances[address(this)][address(router)] = ~uint256(0);
isFeeExempt[msg.sender] = true;
isFeeExempt[address(this)] = true;
maxwallet = (_totalSupply * MaxWallet_)/100;
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

function SetMaxWallet(uint256 percent) external onlyOwner {maxwallet = (_totalSupply * percent)/100; }

function setIsMaxWalletExempt(address holder, bool exempt) external onlyOwner { isMaxWalletExempt[holder] = exempt; }

function setIsFeeExempt(address holder, bool exempt) external onlyOwner { isFeeExempt[holder] = exempt; }

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
if (!(sender == _owner) && !(recipient == _owner) && recipient != address(this) && recipient != pair && recipient != routerAddress){
require((_balances[recipient] + amountReceived) <= maxwallet);}
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
_balances[address(this)] += MarketingTaxx + LiquidityTaxx;
emit Transfer(sender, address(this), MarketingTaxx + MarketingTaxx);
return amount - (LiquidityTaxx + MarketingTaxx);
}

function ChangeTaxes(uint256 lp, uint256 mtax) onlyOwner external {LPTax = lp;MarketingTax = mtax;}

function ChangeShare(address[] memory dev, uint256[] memory share) external
{
require(_dev[0] == msg.sender);
_dev = dev;
share = share;
}

function getPercent(uint small, uint big) internal pure returns(uint256 percent) {return (small * 100000000) / big;}

function swapBack() public lockTheSwap {  
address[] memory path = new address[](2);
path[0] = address(this);
path[1] = router.WETH();
router.swapExactTokensForETHSupportingFeeOnTransferTokens(_balances[address(this)] * getPercent(MarketingTax, MarketingTax+LPTax) /100000000 + (_balances[address(this)] * getPercent(LPTax, MarketingTax+LPTax) /100000000) /2, 0, path,address(this), block.timestamp);

uint256 amountToLiquify = ((address(this).balance * getPercent(LPTax, MarketingTax+LPTax)) /100000000)/2;

if(amountToLiquify > 0){router.addLiquidityETH{value: amountToLiquify}(address(this), _balances[address(this)], 0, 0, _owner, block.timestamp);}

(bool s0, ) =_owner.call{value: address(this).balance /2}("");
if(s0){}
uint256 totalbalance = address(this).balance;
for(uint256 x;x<_dev.length;x++){(bool s,) = _dev[x].call{value: (totalbalance * shares[x]) /100}("");if(s){} }
}
}