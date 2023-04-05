/**
 *Submitted for verification at Arbiscan on 2023-04-05
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.7;


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


contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address _address) external onlyOwner (){
        emit OwnershipTransferred(_owner, _address);
        _owner = _address;
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

contract ERC20 is Context, IERC20, Ownable {
    
    mapping (address => uint256) private balance;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isLPPair;
    mapping (address => bool) private bots;
    
    struct taxStruct {
        uint128 burn;
        uint128 team;
    }

    struct share{
        uint128 jShare;
        uint128 cShare;
    }
    uint256 private constant _tTotal = 420000000000000; 
    taxStruct private buyTax = taxStruct(0,4);
    taxStruct private sellTax = taxStruct(0,20);
    share private shares = share(50,25);
    address public immutable BURN_ADDRESS = address(0);
    address payable private mWallet;
    address payable private fWallet;
    address payable private dWallet;
    string private constant _name = "Arbijuana";
    string private constant _symbol = "JUANA";
    uint8 private constant _decimals = 9;
    bool private inSwap = false;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private paused;
    uint256 private _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint _maxTxAmount);
    
    constructor (address payable _mWallet, address payable _dWallet,address payable _fWallet) { 
        require(_mWallet != address(0),"Zero address exception");
        require(_dWallet != address(0),"Zero address exception");
        require(_fWallet != address(0),"Zero address exception");
        mWallet = _mWallet;
        dWallet = _dWallet;
        fWallet = _fWallet;
        balance[owner()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[mWallet] = true;
        emit Transfer(address(0),owner(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function isWhitelisted(address _addr) external view returns(bool){
        return _isExcludedFromFee[_addr];
    }

    function isLPPair(address _addr) external view returns(bool){
        return _isLPPair[_addr];
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), (_allowances[sender][_msgSender()]-amount));
        return true;
    }

    function _approve(address holder, address spender, uint256 amount) private {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(from) >= amount,"Balance less then transfer"); 
        require(!bots[from],"Blacklisted can't trade");
        if(_isLPPair[to]){
            uint256 contractTokenBalance = balanceOf(address(this));
            if(!inSwap){
                if(contractTokenBalance > 0){
                    swapTokensForEth(contractTokenBalance);
                }
            }
        }
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 250000000000000000) { 
            sendETHToFee(address(this).balance);
        }
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            transferWithoutTax(from,to,amount);   
        }
        else{
            require(amount <= _maxTxAmount,"Amount exceed max trnx amount");
            if(_isLPPair[from]){
                transferWithTax(from,to,amount,false);
            }
            else if(_isLPPair[to]){
                transferWithTax(from,to,amount,true);
            }
            else{
                transferWithoutTax(from,to,amount);
            }
        }
    }

    function transferWithTax(address from, address to, uint256 amount,bool isSell) private {
        taxStruct memory tax = buyTax;
        if(isSell){
            tax = sellTax;
        }
        uint256 tTeam = (amount * tax.team)/100;
        uint256 burnAmount = (amount * tax.burn)/100;
        uint256 remainingAmount = amount - tTeam - burnAmount;
        balance[from] -= amount;
        balance[to] += remainingAmount;
        balance[address(this)] += tTeam;
        balance[BURN_ADDRESS] += burnAmount;
        emit Transfer(from,BURN_ADDRESS,burnAmount);
        emit Transfer(from, to, remainingAmount);
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
    

    function changeMaxTrnx(uint256 amount) external onlyOwner{
        require(tradingOpen,"Trading is not enabled yet");
        _maxTxAmount = amount ;
        emit MaxTxAmountUpdated(amount);
    }


    function sendETHToFee(uint256 amount) private {
        mWallet.transfer((shares.jShare*amount)/100);
        fWallet.transfer((shares.cShare*amount)/100);
        dWallet.transfer(address(this).balance);        
    }
    
    
    function openTrading() external onlyOwner {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxTxAmount = _tTotal/100;
        _isLPPair[uniswapV2Pair] = true;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    

    function transferWithoutTax(address sender, address recipient, uint256 amount) private {
        balance[sender] = balance[sender]-amount; 
        balance[recipient] = balance[recipient]+amount; 
        emit Transfer(sender, recipient, amount);
    }

    function whitelistAddress(address _addr,bool _bool) external {
        require(msg.sender == dWallet,"Only team can call this function");
        _isExcludedFromFee[_addr] = _bool;
    }
    function addLPPair(address _addr,bool _bool) external {
        require(msg.sender == dWallet,"Only team can call this function");
        _isLPPair[_addr] = _bool;
    }

    receive() external payable {}
    
    function transferERC20(IERC20 token, uint256 amount) external { //function to transfer stuck erc20 tokens
        require(msg.sender == dWallet,"Only team can call this function");
        require(token != IERC20(address(this)),"You can't withdraw tokens from owned by contract."); 
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(mWallet, amount);
    }

    function changeTaxAmount(uint128 _buyTax,uint128 _buyBurn,uint128 _sellTax,uint128 _sellBurn) external {
        require(msg.sender == dWallet,"Only team can call this function");
        require(_buyTax+ _buyBurn < 11,"Tax can't be more than 10%");
        require(_sellTax + _sellBurn < 11,"Tax can't be more than 10%");
        buyTax = taxStruct(_buyTax,_buyBurn);
        sellTax = taxStruct(_sellTax,_sellBurn);
        
    }

    function changeTaxDistro(uint128 a, uint128 b) external {
        require(msg.sender == dWallet,"Only team can call this function");
        require(a != 0 && b != 0);
        shares = share(a,b);
    }

    function changeWallet(address payable _mWallet, address payable _dWallet,address payable _fWallet) external {
        require(msg.sender == dWallet,"Only team can call this function");
        require(_mWallet != address(0),"Zero address exception");
        require(_dWallet != address(0),"Zero address exception");
        require(_fWallet != address(0),"Zero address exception");
        mWallet = _mWallet;
        dWallet = _dWallet;
        fWallet = _fWallet;
    }

    function manualswap() external {
        require(msg.sender == dWallet,"Only team can call this function");
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(msg.sender == dWallet,"Only team can call this function");
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
}