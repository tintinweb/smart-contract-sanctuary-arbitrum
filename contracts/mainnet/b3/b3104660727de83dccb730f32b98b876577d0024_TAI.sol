/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// SPDX-License-Identifier: MIT

 pragma solidity >=0.5.0;

interface ICamelotFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );
 
    function owner() external view returns (address);

    function feePercentOwner() external view returns (address);

    function setStableOwner() external view returns (address);

    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);

    function referrersFeeShare(address) external view returns (uint256);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function feeInfo()
        external
        view
        returns (uint _ownerFeeShare, address _feeTo);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/interfaces/ICamelotRouter.sol


pragma solidity >=0.6.2;

interface ICamelotRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

pragma solidity 0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
} 

interface IERC20 { 
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(account, account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract TAI is ERC20, Ownable{
    using Address for address payable;
    
    ICamelotRouter public router;
    address public pair; 
    
    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;

    ICamelotFactory private immutable factory =
        ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652);

    uint256 tsupply = 1e16 * 10 ** decimals();
    uint256 public swapThreshold = tsupply * 5/1000;
    uint256 public maxTxAmount = tsupply * 1/100;
    uint256 public maxWalletAmount = tsupply * 100/100; 
    
    address private devWallet;
    bool private initialized;

    
    struct Taxes {
        uint256 liquidity; 
        uint256 dev;
    }
    
    Taxes public taxes = Taxes(0,0);
    Taxes public sellTaxes = Taxes(20,5);
    uint256 public totalTax = 0;
    uint256 public totalSellTax = 25;
    
    mapping (address => bool) public excludedFromFees;

    mapping(address => bool) public blacklists;

    address private constant ZERO = 0x0000000000000000000000000000000000000000;
    
    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }
        
    constructor() ERC20("TYRE AI", "TAI") {
        devWallet = msg.sender;
        _mint(msg.sender, tsupply); 
        excludedFromFees[msg.sender] = true;

        ICamelotRouter _router = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

        router = _router;
        excludedFromFees[address(this)] = true;
        excludedFromFees[devWallet] = true; 
    }

    function initializePair() external onlyOwner {
        require(!initialized, "Already initialized");
        pair = factory.createPair(address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1), address(this)); 
        initialized = true; 
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!blacklists[sender] && !blacklists[recipient], "Blacklisted");  
        
        if(!excludedFromFees[sender] && !excludedFromFees[recipient] && !swapping){
            require(tradingEnabled, "Trading not active yet");
            require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
            if(recipient != pair){
                require(balanceOf(recipient) + amount <= maxWalletAmount, "You are exceeding maxWalletAmount");
            }
        } 

        uint256 fee;
        
  
        if (swapping || excludedFromFees[sender] || excludedFromFees[recipient]) fee = 0;
          
 
        else{
            if(recipient == pair) fee = amount * totalSellTax / 100;
            else fee = amount * totalTax / 100;
        }
         

        if (swapEnabled && !swapping && sender != pair && fee > 0) swapForFees();

        super._transfer(sender, recipient, amount - fee);
        if(fee > 0) super._transfer(sender, address(this) ,fee);

    }

     function swapForFees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {

            uint256 denominator = totalSellTax * 2;
            uint256 tokensToAddLiquidityWith = contractBalance * sellTaxes.liquidity / denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;
            uint256 initialBalance = address(this).balance;
    
            swapTokensForETH(toSwap);
    
            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance= deltaBalance / (denominator - sellTaxes.liquidity);
            uint256 ethToAddLiquidityWith = unitBalance * sellTaxes.liquidity;
    
            if(ethToAddLiquidityWith > 0){
                // Add liquidity to Camelot
                addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
            }
            uint256 devAmt = unitBalance * 2 * sellTaxes.dev;
            if(devAmt > 0){
                payable(devWallet).sendValue(devAmt);
            }
        }
    }


    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH(); 
        

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this),address(ZERO), block.timestamp);

    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            devWallet,
            block.timestamp
        );
    }

    function setSwapEnabled(bool state) external onlyOwner {
        swapEnabled = state;
    }

    function setSwapThreshold(uint256 new_amount) external onlyOwner {
        swapThreshold = new_amount;
    }

    function enableTrading() external onlyOwner{
        require(!tradingEnabled, "Trading already active");
        tradingEnabled = true;
    }
    function setBuyTaxes(uint256 _liquidity, uint256 _dev) external onlyOwner{
        taxes = Taxes(_liquidity, _dev);
        totalTax = _liquidity + _dev;
    }

    function setSellTaxes(uint256 _liquidity, uint256 _dev) external onlyOwner{
        sellTaxes = Taxes(_liquidity, _dev);
        totalSellTax = _liquidity + _dev;
    }
    
    function updateDBTeamWallet(address newWallet) external onlyOwner{
        devWallet = newWallet;
    }

    function updateRouterAndPair(ICamelotRouter _router, address _pair) external onlyOwner{
        router = _router;
        pair = _pair;
    }
    
    function updateExcludedFromFees(address _address, bool state) external onlyOwner {
        excludedFromFees[_address] = state;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }
    
    function updateMaxTxAmount(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**decimals();
    }
    
    function updateMaxWalletAmount(uint256 amount) external onlyOwner{
        maxWalletAmount = amount * 10**decimals();
    }

    function rescueERC20(address tokenAddress, uint256 amount) external {
        IERC20(tokenAddress).transfer(devWallet, amount);
    }

    function rescueETH(uint256 weiAmount) external {
        payable(devWallet).sendValue(weiAmount);
    }

    function manualSwap(uint256 amount) external{
        require(msg.sender == devWallet);
        swapTokensForETH(amount);
        payable(devWallet).sendValue(address(this).balance);       
    }

    // fallbacks
    receive() external payable {}
    
}