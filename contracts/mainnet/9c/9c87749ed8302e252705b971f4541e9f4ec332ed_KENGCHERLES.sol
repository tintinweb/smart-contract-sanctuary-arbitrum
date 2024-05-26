/**
 *Submitted for verification at Arbiscan.io on 2024-05-26
*/

/**
 *Submitted for verification at Arbiscan.io on 2024-05-26
*/

//IT'S GETTING HOT RIGHT NOW
// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address public _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
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
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
contract KENGCHERLES is Context , IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address payable private _taxWallet;

    uint256 public _tax = 0; //0%
    uint256 private _tier1 = 300; //30%
    uint256 private _tier2 = 200; //20%
    uint256 private _tier3 = 100; //10%
    uint256 private _tier4 = 3; //0.3%
    

    // Reduction Rules
    uint256 private _buyCount=0;
    uint256 private _antiSniperCount = 30;
    uint256 private _reductingPeriod1 = 60; // Reduce tax at 90 - Tier 2
    uint256 private _reductingPeriod2 = 90; // Reduce tax at 120 - Tier 3
    uint256 private _reductingPeriod3 = 45 minutes; // Reduce tax after opened - Tier 4
    uint256 private _preventSwapBefore= 31; // prevent the contract from swapping before 40 buys


    uint256 public _tradingOpened;

    // Anti Sniper
    bool public antiSniperEnabled = true;
    mapping(address => bool) private antisniper;

    // Token Information
    uint8 public constant _decimals = 9;
    uint256 public constant _tTotal = 2600000000 * 10**_decimals;
    string public constant _name = unicode"KENG CHERLES";
    string public constant _symbol = unicode"KENG";

    // Contract Swap Rules
    uint256 private _taxSwapThreshold= 100000 * 10**_decimals; //0.01%
    uint256 private _maxTaxSwap= 26000000 * 10**_decimals; //1%

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address taxWallet) {
        _owner = _msgSender();
        _taxWallet = payable(taxWallet);
        _balances[_msgSender()] = _tTotal;
        antisniper[owner()] = true;
        antisniper[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {

            taxAmount = amount.mul(_tax).div(1000);

            //Anti Sniper Rule
            if (antiSniperEnabled && from!= address(this)) {
                require(antisniper[to], "Failed to snipe");
            }
            
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _buyCount++;
                
                // Disable antisniper & tax
                if (_buyCount >= _antiSniperCount && antiSniperEnabled) {
                    antiSniperEnabled = false;
                    _tax = _tier1;
                }
            }
            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul(_tax).div(1000);

                // Reduce Tax 
                if (_buyCount >= _reductingPeriod1 && _tax == _tier1) {
                    _tax = _tier2;
                }
                if (_buyCount >= _reductingPeriod2 && _tax == _tier2) {
                    _tax = _tier3;
                }
                if (block.timestamp >= _tradingOpened.add(_reductingPeriod3) && _tax == _tier3) {
                    _tax = _tier4;
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth((amount < contractTokenBalance) ? 
                amount : (contractTokenBalance < _maxTaxSwap) ? contractTokenBalance : _maxTaxSwap);
                
                
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function openTrading() external onlyOwner() {  
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        _tradingOpened = block.timestamp;
    }
    // Function to add an array of wallets

    function addAntiSniper(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
        antisniper[accounts[i]] = true;
        }
    }
  
    receive() external payable {}
}