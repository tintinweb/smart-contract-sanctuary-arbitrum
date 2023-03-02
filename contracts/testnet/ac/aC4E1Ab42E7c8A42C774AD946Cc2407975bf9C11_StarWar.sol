/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

/**
 *Submitted for verification at Arbiscan on 2023-02-24
*/

// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
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
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ILpPair {
    function sync() external;
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract StarWar is ERC20, Ownable {

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;

    IDexRouter public immutable dexRouter;
    address public immutable lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address public operationsAddress;
    address public rewardsAddress;
    address public reserveAddress;
    address public liquidityAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellRewardsFee;
    uint256 public sellReserveFee;

    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;
    uint256 public tokensForRewards;
    uint256 public tokensForReserve;
    
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public isExcludedMaxTransactionAmount;

    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event EnabledTrading();
    event RemovedLimits();
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdatedMaxBuyAmount(uint256 newAmount);
    event UpdatedMaxSellAmount(uint256 newAmount);
    event UpdatedSwapTokensAtAmount(uint256 newAmount);
    event UpdatedMaxWalletAmount(uint256 newAmount);
    event UpdatedBuyFee(uint256 newAmount);
    event UpdatedSellFee(uint256 newAmount);
    event UpdatedOperationsAddress(address indexed newWallet);
    event UpdatedRewardsAddress(address indexed newWallet);
    event UpdatedReserveAddress(address indexed newWallet);
    event UpdatedLiquidityAddress(address indexed newWallet);
    event MaxTransactionExclusion(address _address, bool excluded);
    event OwnerForcedSwapBack(uint256 timestamp);
    event TransferForeignToken(address token, uint256 amount);

    constructor() ERC20("StarWar", "STAR") {
        
        address newOwner = msg.sender; // can leave alone if owner is deployer.

        // initialize router
        IDexRouter _dexRouter = IDexRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); //Testnet: 0x38eEd6a71A4ddA9d7f776946e3cfa4ec43781AE6  // Mainnet: 0x1b02da8cb0d097eb8d57a175b88c7d8b47997506
        dexRouter = _dexRouter;

        // create pair
        lpPair = 0xBF8dC4d2fA5111274e29eA28e4a212A593522541;//IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 _totalSupply = 100 * 1e12 * 1e18;
        
        maxBuyAmount = _totalSupply * 1 / 1000;
        maxSellAmount = _totalSupply * 1 / 1000;
        swapTokensAtAmount = _totalSupply * 25 / 100000;

        buyTotalFees = 3;

        sellOperationsFee = 1;
        sellLiquidityFee = 3;
        sellRewardsFee = 15;
        sellReserveFee = 2;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellRewardsFee + sellReserveFee;

        // update these!
        operationsAddress = address(0x2010d806f67Bbd4aE7FC2eD3D5Ef696A8D7A1358);
        rewardsAddress = address(msg.sender);
        reserveAddress = address(0xF3DfC6beCF252A85e8629208D4bBA53DFEDA5C1b);
        liquidityAddress = address(0xd31672b14207248F0aeAB0251432c5a47EB3560F);

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(operationsAddress), true);
        _excludeFromMaxTransaction(address(reserveAddress), true);
        _excludeFromMaxTransaction(address(liquidityAddress), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(operationsAddress), true);
        excludeFromFees(address(reserveAddress), true);
        excludeFromFees(address(liquidityAddress), true);

        _createInitialSupply(address(newOwner), _totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    function enableTrading(uint256 blocksForPenalty) external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        require(blocksForPenalty < 10, "Cannot make penalty blocks more than 10");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        emit EnabledTrading();
    }

    function pauseSwapBack() external onlyOwner {
        swapEnabled = false;
    }

    function unpauseSwapBack() external onlyOwner {
        swapEnabled = true;
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        emit RemovedLimits();
    }
    
    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set max buy amount lower than 0.1%");
        maxBuyAmount = newNum * (10**18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }
    
    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set max sell amount lower than 0.1%");
        maxSellAmount = newNum * (10**18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 1 / 1000, "Swap amount cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmount = newAmount;
        emit UpdatedSwapTokensAtAmount(maxSellAmount);
  	}
    
    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 600, "Can only airdrop 600 wallets per txn due to gas limits");
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = amountsInTokens[i];
            super._transfer(msg.sender, wallet, amount);
        }
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != lpPair, "Cannot remove uniswap pair from max txn");
        }
        isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != lpPair || value, "The pair cannot be removed from automatedMarketMakerPairs");
        automatedMarketMakerPairs[pair] = value;
        _excludeFromMaxTransaction(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 liquidityFee) external onlyOwner {
        buyTotalFees = liquidityFee;
        require(buyTotalFees <= 2, "Must keep fees at 2% or less");
        emit UpdatedBuyFee(buyTotalFees);
    }

    function updateSellFees(uint256 operationsFee, uint256 liquidityFee, uint256 rewardsFee, uint256 reserveFee) external onlyOwner {
        require(operationsFee <= 1, "Exceeded max fee for operations");
        sellOperationsFee = operationsFee;
        require(liquidityFee <= 5, "Exceeded max fee for liquidity");
        sellLiquidityFee = liquidityFee;
        require(rewardsFee <= 20, "Exceeded max fee for rewards");
        sellRewardsFee = rewardsFee;
        require(reserveFee <= 3, "Exceeded max fee for reserve");
        sellReserveFee = reserveFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellRewardsFee + sellReserveFee;
        require(sellTotalFees <= 20, "Must keep fees at 20% or less");
        emit UpdatedSellFee(sellTotalFees);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if(amount == 0){
            super._transfer(from, to, 0);
            return;
        }
        
        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }
        
        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
                //when buy
                if (automatedMarketMakerPairs[from] && !isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxBuyAmount, "Buy transfer amount exceeds the max buy.");
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxSellAmount, "Sell transfer amount exceeds the max sell.");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && automatedMarketMakerPairs[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // bot/sniper penalty.
            if(earlyBuyPenaltyInEffect() && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && buyTotalFees > 0){

                fees = (amount * buyTotalFees) * 100;
        	    tokensForLiquidity += (fees * buyTotalFees) / buyTotalFees;
            }

            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = (amount * sellTotalFees) / 100;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForOperations += (fees * sellOperationsFee) / sellTotalFees;
                tokensForRewards += (fees * sellRewardsFee) / sellTotalFees;
                tokensForReserve += (fees * sellReserveFee) / sellTotalFees;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = (amount * buyTotalFees) / 100;
        	    tokensForLiquidity += (fees * buyTotalFees) / buyTotalFees;
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function earlyBuyPenaltyInEffect() public view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0,  0,  address(liquidityAddress), block.timestamp);
    }

    function swapBack() private {

        if(tokensForRewards > 0 && balanceOf(address(this)) >= tokensForRewards) {
            _transfer(address(this), address(rewardsAddress), tokensForRewards);
        }
        tokensForRewards = 0;

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForOperations + tokensForReserve;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 10){
            contractBalance = swapTokensAtAmount * 10;
        }
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        
        swapTokensForEth(contractBalance - liquidityTokens);
        
        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForOperations = ethBalance * tokensForOperations / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForReserve = ethBalance * tokensForReserve / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForOperations + ethForReserve;
            
        tokensForLiquidity = 0;
        tokensForOperations = 0;
        tokensForReserve = 0;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        if(ethForReserve > 0){
            bool success;
            (success, ) = address(reserveAddress).call{value: ethForReserve}("");
        }

        if(address(this).balance > 0){
            bool success;
            (success, ) = address(operationsAddress).call{value: address(this).balance}("");
        }
    }

    function transferForeignToken(address token, address to) external onlyOwner returns (bool _sent) {
        require(token != address(0), "token address cannot be 0");
        require(token != address(this) || !tradingActive, "Can't withdraw native tokens while trading is active");
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        _sent = IERC20(token).transfer(to, _contractBalance);
        emit TransferForeignToken(token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function setOperationsAddress(address newOperationsAddress) external onlyOwner {
        require(newOperationsAddress != address(0), "address cannot be 0");
        operationsAddress = payable(newOperationsAddress);
        emit UpdatedOperationsAddress(newOperationsAddress);
    }
    
    function setRewardsAddress(address newRewardsAddress) external onlyOwner {
        require(newRewardsAddress != address(0), "address cannot be 0");
        rewardsAddress = payable(newRewardsAddress);
        emit UpdatedRewardsAddress(newRewardsAddress);
    }

    function setReserveAddress(address newReserveAddress) external onlyOwner {
        require(newReserveAddress != address(0), "address cannot be 0");
        reserveAddress = payable(newReserveAddress);
        emit UpdatedReserveAddress(newReserveAddress);
    }

    function setLiquidityAddress(address newLiquidityAddress) external onlyOwner {
        require(newLiquidityAddress != address(0), "address cannot be 0");
        liquidityAddress = payable(newLiquidityAddress);
        emit UpdatedLiquidityAddress(newLiquidityAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }
}