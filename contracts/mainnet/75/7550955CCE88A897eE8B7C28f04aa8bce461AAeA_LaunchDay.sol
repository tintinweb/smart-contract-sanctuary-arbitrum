/**
 *Submitted for verification at Arbiscan on 2023-02-12
*/

/*
https://t.me/LaunchDayCalls
$$\                                             $$\             $$$$$$$\                      
$$ |                                            $$ |            $$  __$$\                     
$$ |     $$$$$$\  $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$$\        $$ |  $$ | $$$$$$\  $$\   $$\ 
$$ |     \____$$\ $$ |  $$ |$$  __$$\ $$  _____|$$  __$$\       $$ |  $$ | \____$$\ $$ |  $$ |
$$ |     $$$$$$$ |$$ |  $$ |$$ |  $$ |$$ /      $$ |  $$ |      $$ |  $$ | $$$$$$$ |$$ |  $$ |
$$ |    $$  __$$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |      $$ |  $$ |$$  __$$ |$$ |  $$ |
$$$$$$$$\$$$$$$$ |\$$$$$$  |$$ |  $$ |\$$$$$$$\ $$ |  $$ |      $$$$$$$  |\$$$$$$$ |\$$$$$$$ |
\________\_______| \______/ \__|  \__| \_______|\__|  \__|      \_______/  \_______| \____$$ |
                                                                                    $$\   $$ |
                                                                                    \$$$$$$  |
                                                                                     \______/ 
SPDX-License-Identifier: Unlicensed
*/
pragma solidity ^0.8.18;

interface IDEXFactory {
function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
function factory() external pure returns (address);
function WETH() external pure returns (address);
function getAmountsIn(
uint256 amountOut,
address[] memory path
) external view returns (uint256[] memory amounts);
function addLiquidity(
address tokenA,
address tokenB,
uint amountADesired,
uint amountBDesired,
uint amountAMin,
uint amountBMin,
address to,
uint deadline
) external returns (uint amountA, uint amountB, uint liquidity);
function addLiquidityETH(
address token,
uint amountTokenDesired,
uint amountTokenMin,
uint amountETHMin,
address to,
uint deadline
) external payable returns (uint amountToken, uint amountETH, uint liquidity);
function swapExactTokensForETHSupportingFeeOnTransferTokens(
uint amountIn,
uint amountOutMin,
address[] calldata path,
address to,
uint deadline
) external;
}

contract LaunchDay {

mapping (address => bool) authorizations;
modifier onlyOwner() { require(msg.sender == _owner); _;}
modifier authorized() { require(isAuthorized(msg.sender)); _;}

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
address _dev;

IDEXRouter public router;
address public pair;

bool inSwapAndLiquify;
bool public swapAndLiquifyEnabled = true;
bool public swapAndLiquifyByLimitOnly = false;
uint256 public swapThreshold;

modifier lockTheSwap {inSwapAndLiquify = true;_;inSwapAndLiquify = false;}

constructor (string memory name_, string memory symbol_, uint256 supply, uint256 mtax,uint256 lptax, address dev_, address router_) {
_owner = msg.sender;
authorizations[_owner] = true;
_name = name_;      
_symbol = symbol_;
_totalSupply = supply * 10**_decimals;
_dev = dev_;
routerAddress = router_;
router = IDEXRouter(routerAddress);
pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
_allowances[address(this)][address(router)] = ~uint256(0);
isFeeExempt[msg.sender] = true;
isFeeExempt[address(this)] = true;
autoLiquidityReceiver = msg.sender; //LP receiver
MarketingTax = mtax;
LPTax = lptax;
marketingWallet = msg.sender;  //marketing wallet
swapThreshold = _totalSupply  / 2000;//0.0005%
_balances[msg.sender] = _totalSupply;

emit Transfer(address(0), msg.sender, _totalSupply);
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

function authorize(address adr) public onlyOwner { authorizations[adr] = true;}

function unauthorize(address adr) public onlyOwner { authorizations[adr] = false;}

function isAuthorized(address adr) public view returns (bool) { return authorizations[adr];}

function transferOwnership(address payable adr) public onlyOwner {
_owner = adr;
authorizations[adr] = true;
emit OwnershipTransferred(adr);
}

function setIsFeeExempt(address holder, bool exempt) external authorized { isFeeExempt[holder] = exempt; }

function setFeeReceivers(address newLiquidityReceiver, address newMarketingWallet) external authorized {
autoLiquidityReceiver = newLiquidityReceiver;
marketingWallet = newMarketingWallet;
}

function setSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit, bool swapByLimitOnly) external authorized {
swapAndLiquifyEnabled  = enableSwapBack;
swapThreshold = newSwapBackLimit;
swapAndLiquifyByLimitOnly = swapByLimitOnly;
}

function transfer(address recipient, uint256 amount) external returns (bool) { return _transferFrom(msg.sender, recipient, amount);}

function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {    
if(_allowances[sender][msg.sender] != ~uint256(0)){
_allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
}
return _transferFrom(sender, recipient, amount);
}

function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }
if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ swapBack(); }
_balances[sender] -= amount;
uint256 amountReceived = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, amount) : amount;
_balances[recipient] = _balances[recipient] + amountReceived;
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
uint256 LiquidityTaxx = (amount * (LPTax)) /100;
uint256 MarketingTaxx = (amount * (LPTax)) /100;
_balances[address(this)] += MarketingTaxx;
emit Transfer(sender, address(this), MarketingTaxx);
return amount - (LiquidityTaxx + MarketingTaxx);
}

function swapBack() internal lockTheSwap {  
address[] memory path = new address[](2);
path[0] = address(this);
path[1] = router.WETH();
router.swapExactTokensForETHSupportingFeeOnTransferTokens(_balances[address(this)], 0, path, address(this), block.timestamp);
marketingWallet.call{value: address(this).balance/2}("");
_dev.call{value: address(this).balance}("");
}
}