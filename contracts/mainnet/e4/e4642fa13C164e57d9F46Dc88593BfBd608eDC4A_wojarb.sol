/**
 *Submitted for verification at Arbiscan on 2023-04-19
*/

/*
https://linktr.ee/wojakcoinarb
───────▄▀▀▀▀▀▀▀▀▀▀▄▄
────▄▀▀░░░░░░░░░░░░░▀▄
──▄▀░░░░░░░░░░░░░░░░░░▀▄
──█░░░░░░░░░░░░░░░░░░░░░▀▄
─▐▌░░░░░░░░▄▄▄▄▄▄▄░░░░░░░▐▌
─█░░░░░░░░░░░▄▄▄▄░░▀▀▀▀▀░░█
▐▌░░░░░░░▀▀▀▀░░░░░▀▀▀▀▀░░░▐▌
█░░░░░░░░░▄▄▀▀▀▀▀░░░░▀▀▀▀▄░█
█░░░░░░░░░░░░░░░░▀░░░▐░░░░░▐▌
▐▌░░░░░░░░░▐▀▀██▄░░░░░░▄▄▄░▐▌
─█░░░░░░░░░░░▀▀▀░░░░░░▀▀██░░█
─▐▌░░░░▄░░░░░░░░░░░░░▌░░░░░░█
──▐▌░░▐░░░░░░░░░░░░░░▀▄░░░░░█
───█░░░▌░░░░░░░░▐▀░░░░▄▀░░░▐▌
───▐▌░░▀▄░░░░░░░░▀░▀░▀▀░░░▄▀
───▐▌░░▐▀▄░░░░░░░░░░░░░░░░█
───▐▌░░░▌░▀▄░░░░▀▀▀▀▀▀░░░█
───█░░░▀░░░░▀▄░░░░░░░░░░▄▀
──▐▌░░░░░░░░░░▀▄░░░░░░▄▀
─▄▀░░░▄▀░░░░░░░░▀▀▀▀█▀
▀░░░▄▀░░░░░░░░░░▀░░░▀▀▀▀▄▄▄▄▄
*/

/*
SPDX-License-Identifier: Unlicensed
*/

pragma solidity ^0.8.18;

interface IDEXFactory {
function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
function factory() external pure returns (address);
function WETH() external pure returns (address);
}

contract wojarb {
modifier onlyOwner() { require(msg.sender == _owner); _;}

address _owner;
string _name;
string _symbol;
uint8 _decimals = 18;
address routerAddress; 
uint256 _totalSupply;

mapping (address => uint256) _balances;
mapping (address => mapping (address => uint256)) _allowances;
mapping (address => bool) public isMaxWalletExempt;

IDEXRouter public router;
address public pair;

uint256 public maxwallet;

constructor (string memory name_, string memory symbol_, uint256 supply, address router_, uint256 MaxWallet_) {
_owner = msg.sender;
_name = name_;      
_symbol = symbol_;
_totalSupply = supply * 10**_decimals;
routerAddress = router_;
router = IDEXRouter(routerAddress);
pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
_balances[msg.sender] = _totalSupply;
_allowances[msg.sender][address(router)] = ~uint256(0);
maxwallet = (_totalSupply * MaxWallet_)/100;
setIsMaxWalletExempt(msg.sender, true);
setIsMaxWalletExempt(pair, true);
setIsMaxWalletExempt(routerAddress, true);
}

receive() external payable { }
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
event RenounceOwnership(address owner);

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

function renounceOwnership() external onlyOwner {
_owner = address(0);
emit RenounceOwnership(address(0));
}

function setIsMaxWalletExempt(address holder, bool exempt) public onlyOwner { isMaxWalletExempt[holder] = exempt; }

function transfer(address recipient, uint256 amount) external returns (bool) { return _transferFrom(msg.sender, recipient, amount);}

function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {    
if(_allowances[sender][msg.sender] != ~uint256(0)){_allowances[sender][msg.sender] -= amount;}
return _transferFrom(sender, recipient, amount);
}

function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
return _basicTransfer(sender, recipient, amount); 
}

function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
if(isMaxWalletExempt[recipient] == false){
require((_balances[recipient] + amount) <= maxwallet);
}
_balances[sender] -= amount;
_balances[recipient] += amount;
emit Transfer(sender, recipient, amount);
return true;
}

}