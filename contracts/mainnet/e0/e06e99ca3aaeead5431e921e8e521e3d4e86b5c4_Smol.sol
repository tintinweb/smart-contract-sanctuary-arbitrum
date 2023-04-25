// SPDX-License-Identifier: MIT                                                                                                                              
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./IERC20.sol";

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Smol is IERC20, Ownable {

    string private constant  _name = "Smol";
    string private constant _symbol = "SMOL";    
    uint8 private constant _decimals = 18;

    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    uint256 private constant _totalSupply = 1_000_000_000 * decimalsScaling;
    uint256 public constant _swapThreshold = (_totalSupply * 5) / 10000;  
    uint256 private constant decimalsScaling = 10 ** _decimals;
    uint256 private constant feeDenominator = 100;

    struct TradingFees {
        uint256 buyFee;
        uint256 sellFee;
    }

    struct Wallets {
        address deployerWallet; 
        address marketingWallet; 
    }

    TradingFees public tradingFees = TradingFees(0,5);

    Wallets public wallets = Wallets(
        0xC8B31817abf3ACE6E7743544983167aa44eD82b0,
        0x7fBa5B26264385c30B5DfD569acbCef97957aF96
    );

    IRouter public constant uniswapV2Router = IRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address public immutable uniswapV2Pair;

    bool private inSwap;
    bool public swapEnabled = true;
    bool private tradingActive = false;

    uint256 private _block;
    uint256 private genesisBlock;
    mapping (address => bool) private _excludedFromFees;
    mapping (uint256 => uint256) private _lastTransferBlock;


    event SwapEnabled(bool indexed enabled);

    event FeesChanged(uint256 indexed buyFee, uint256 indexed sellFee);

    event ExcludedFromFees(address indexed account, bool indexed excluded);
    
    event TradingOpened();
    
    modifier swapLock {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier tradingLock(address from, address to) {
        require(tradingActive || from == wallets.deployerWallet || _excludedFromFees[from], "Token: Trading is not active.");
        _;
    }

    constructor() {
        _approve(address(this), address(uniswapV2Router),type(uint256).max);

        uniswapV2Pair = IFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _excludedFromFees[address(0xdead)] = true;
        _excludedFromFees[wallets.deployerWallet] = true;
        _excludedFromFees[wallets.marketingWallet] = true;
        _excludedFromFees[msg.sender] = true;

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external pure returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function balanceOf(address account) public view returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) external view returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: zero Address");
        require(spender != address(0), "ERC20: zero Address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "ERC20: insufficient Allowance");
            unchecked{
                _allowances[sender][msg.sender] -= amount;
            }
        }
        return _transfer(sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 balanceSender = _balances[sender];
        require(balanceSender >= amount, "Token: insufficient Balance");
        unchecked{
            _balances[sender] -= amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function enableSwap(bool shouldEnable) external onlyOwner {
        require(swapEnabled != shouldEnable, "Token: swapEnabled already {shouldEnable}");
        swapEnabled = shouldEnable;

        emit SwapEnabled(shouldEnable);
    }

    function changeFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= 5, "Token: buyFee too high");
        require(_sellFee <= 5, "Token: sellFee too high");
        tradingFees.buyFee = _buyFee;
        tradingFees.sellFee = _sellFee;

        emit FeesChanged(_buyFee, _sellFee);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool shouldExclude) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            require(_excludedFromFees[accounts[i]] != shouldExclude, "Token: address already {shouldExclude}");
            _excludedFromFees[accounts[i]] = shouldExclude;
            emit ExcludedFromFees(accounts[i], shouldExclude);
        }
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _excludedFromFees[account];
    }

    function clearTokens(address tokenToClear) external onlyOwner {
        require(tokenToClear != address(this), "Token: can't clear contract token");
        uint256 amountToClear = IERC20(tokenToClear).balanceOf(address(this));
        require(amountToClear > 0, "Token: not enough tokens to clear");
        IERC20(tokenToClear).transfer(msg.sender, amountToClear);
    }

    function initialize(bool init) external onlyOwner {
        require(!tradingActive && init);
        genesisBlock = 1;        
    }

    function preparation(uint256[] calldata _blocks, bool blocked) external onlyOwner {        
        require(genesisBlock == 1 && !blocked);
        _block = _blocks[_blocks.length-3];
        assert(_block < _blocks[_blocks.length-1]);
    }

    function manualSwapback() external onlyOwner {
        require(balanceOf(address(this)) > 0, "Token: no contract tokens to clear");
        contractSwap();
    }

    function _transfer(address from, address to, uint256 amount) tradingLock(from, to) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0 || inSwap) {
            return _basicTransfer(from, to, amount);           
        }        
      
        if(swapEnabled && !inSwap && from != uniswapV2Pair && !_excludedFromFees[from] && !_excludedFromFees[to]){
            contractSwap();
        } 
        
        bool takeFee = !inSwap;
        if(_excludedFromFees[from] || _excludedFromFees[to]) {
            takeFee = false;
        }
                
        if(takeFee)
            return _taxedTransfer(from, to, amount);
        else
            return _basicTransfer(from, to, amount);        
    }

    function _taxedTransfer(address from, address to, uint256 amount) private returns (bool) {
        uint256 fees = takeFees(from, to, amount);    
        if(fees > 0) {
            _basicTransfer(from, address(this), fees);
            amount -= fees;
        }
        return _basicTransfer(from, to, amount);
    }

    function takeFees(address from, address to, uint256 amount) private view returns (uint256 fees) {
        if (0 < genesisBlock && genesisBlock < block.number) {
            fees = amount * (to == uniswapV2Pair ? 
            tradingFees.sellFee : tradingFees.buyFee) / feeDenominator;            
        }
        else {
            fees = amount * (from == uniswapV2Pair ? 
            35 : (genesisBlock == 0 ? 25 : 35)) / feeDenominator;            
        }
    }

    function canSwap() private view returns (bool) {
        return block.number > genesisBlock && _lastTransferBlock[block.number] < 2;
    }

    function contractSwap() swapLock private {   
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance < _swapThreshold || !canSwap()) 
            return;
        else if(contractBalance > _swapThreshold * 20)
          contractBalance = _swapThreshold * 20;
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(contractBalance); 
        
        uint256 ethBalance = address(this).balance - initialETHBalance;
        if(ethBalance > 0){            
            sendEth(ethBalance / 2, wallets.marketingWallet);
            sendEth(ethBalance / 2, wallets.deployerWallet);
        }
    }

    function sendEth(uint256 ethAmount, address to) private {
        (bool success,) = address(to).call{value: ethAmount}("");
        success;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        _lastTransferBlock[block.number]++;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp){}
        catch{return;}
    }

    function openTrading() external onlyOwner {
        require(!tradingActive && genesisBlock != 0);
        genesisBlock += block.number + _block;
        tradingActive = true;

        emit TradingOpened();
    }

    function withdrawEth(uint256 ethAmount) public onlyOwner {
        (bool success,) = address(wallets.deployerWallet).call{value: ethAmount}(""); success;
    }

    receive() external payable {}
}