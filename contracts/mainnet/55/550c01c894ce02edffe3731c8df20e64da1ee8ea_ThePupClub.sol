/**
 *Submitted for verification at Arbiscan.io on 2023-09-30
*/

//THE PUP CLUB 
//Unlocking Wealth and Opportunity with The Pup Club (TPC). 

//In the dynamic world of cryptocurrency, a new and exciting token has emerged, promising not just financial gains but also the opportunity to be part of an exclusive community. The Pup Club Token, or TPC, is here to revolutionize the way you think about investing and redefining what it means to be a part of a digital ecosystem.
//Please Join Our Official Telegram Channel https://t.me/thepupclubchannel
//Revoluzionizing The Pup Club Token Ecosystem
//WEB: https://thepupclub.tech
//DAPP: https://dapp.thepupclub.tech

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// Library

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    
    // DATA

    address private _owner;
    address private _operator;

    // MAPPING

    mapping(address => bool) internal authorizations;

    // MODIFIER

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    modifier authorized() {
        _checkAuthorization();
        _;
    }
    
    // CONSTRUCTOR

    constructor(
        address adr
    ) {
        _transferOwnership(_msgSender());
        authorizations[_msgSender()] = true;
        _operator = adr;
    }

    // EVENT

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // FUNCTION

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function operator() public view virtual returns (address) {
        return _operator;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function _checkOperator() internal view virtual {
        require(operator() == _msgSender(), "Ownable: caller is not the operator");
    }

    function _checkAuthorization() internal view virtual {
        require(isAuthorized(_msgSender()), "Ownable: caller is not an authorized account");
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function authorize(address adr) public onlyOperator {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOperator {
        authorizations[adr] = false;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function renounceOperator() public virtual onlyOperator {
        _operator = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Interface

interface IERC20 {
    
    //EVENT 

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // FUNCTION

    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address to, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IFactory {

    // FUNCTION

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {

    // FUNCTION

    function WETH() external pure returns (address);
        
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

// Token

contract ThePupClub is Ownable, IERC20 {

    // DATA

    string private constant NAME = "The Pup Club Token";
    string private constant SYMBOL = "TPC";

    uint8 private constant DECIMALS = 18;

    uint256 private _totalSupply;
    
    uint256 public constant FEEDENOMINATOR = 10_000;

    uint256 public buyLaunchpadFee = 300;
    uint256 public buyLiquidityFee = 200;
    uint256 public sellLaunchpadFee = 300;
    uint256 public sellLiquidityFee = 500;
    uint256 public transferLaunchpadFee = 0;
    uint256 public transferLiquidityFee = 0;
    uint256 public launchpadFeeCollected = 0;
    uint256 public liquidityFeeCollected = 0;
    uint256 public totalFeeCollected = 0;
    uint256 public launchpadFeeRedeemed = 0;
    uint256 public liquidityFeeRedeemed = 0;
    uint256 public totalFeeRedeemed = 0;
    uint256 public minSwap = 10_000 ether;

    bool private constant ISTPC = true;

    bool public isFeeActive = false;
    bool public isFeeLocked = false;
    bool public isSwapEnabled = false;
    bool public inSwap = false;

    address public constant ZERO = address(0);
    address public constant DEAD = address(0xdead);

    address public pair;
    address public launchpadReceiver = 0x7cc36394cA6f8132e3d01C5898731FD769194fA4;
    address public liquidityReceiver = 0xe2742e2eA6eE0fB1Fe77d8aA8024fD6Ff0491feF;
    
    IRouter public router;

    // MAPPING

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludeFromFees;

    // MODIFIER

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // CONSTRUCTOR

    constructor(
        address routerAddress
    ) Ownable (_msgSender()) {
        _mint(_msgSender(), 100_000_000 ether);
        
        router = IRouter(routerAddress);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
    }

    // EVENT

    event UpdateRouter(address oldRouter, address newRouter, uint256 timestamp);

    event UpdateMinSwap(uint256 oldMinSwap, uint256 newMinSwap, uint256 timestamp);

    event UpdateFeeActive(bool oldStatus, bool newStatus, uint256 timestamp);

    event UpdateSwapEnabled(bool oldStatus, bool newStatus, uint256 timestamp);

    event RedeemLiquidity(uint256 amountToken, uint256 amountETH, uint256 liquidity, uint256 timestamp);

    event UpdateLaunchpadReceiver(address oldLaunchpadReceiver, address newLaunchpadReceiver, uint256 timestamp);
    
    event UpdateLiquidityReceiver(address oldLiquidityReceiver, address newLiquidityReceiver, uint256 timestamp);

    event AutoRedeem(uint256 launchpadFeeDistribution, uint256 liquidityFeeDistribution, uint256 amountToRedeem, uint256 timestamp);

    // FUNCTION

    /* General */

    receive() external payable {}

    function finalizePresale() external authorized {
        require(!isFeeActive, "Finalize Presale: Fee already active.");
        require(!isSwapEnabled, "Finalize Presale: Swap already enabled.");
        isFeeActive = true;
        isSwapEnabled = true;
    }

    function lockFees() external authorized {
        require(!isFeeLocked, "Lock Fees: All fees were already locked.");
        isFeeLocked = true;
    }

    function redeemAllLaunchpadFee() external {
        uint256 amountToRedeem = launchpadFeeCollected - launchpadFeeRedeemed;
        
        _redeemLaunchpadFee(amountToRedeem);
    }

    function redeemPartialLaunchpadFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= launchpadFeeCollected - launchpadFeeRedeemed, "Redeem Partial Launchpad Fee: Insufficient launchpad fee collected.");
        
        _redeemLaunchpadFee(amountToRedeem);
    }

    function _redeemLaunchpadFee(uint256 amountToRedeem) internal swapping { 
        launchpadFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToRedeem);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToRedeem,
            0,
            path,
            launchpadReceiver,
            block.timestamp
        );
    }

    function redeemAllLiquidityFee() external {
        uint256 amountToRedeem = liquidityFeeCollected - liquidityFeeRedeemed;
        
        _redeemLiquidityFee(amountToRedeem);
    }

    function redeemPartialLiquidityFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= liquidityFeeCollected - liquidityFeeRedeemed, "Redeem Partial Liquidity Fee: Insufficient liquidity fee collected.");
        
        _redeemLiquidityFee(amountToRedeem);
    }

    function _redeemLiquidityFee(uint256 amountToRedeem) internal swapping returns (uint256) {   
        require(msg.sender != liquidityReceiver, "Redeem Liquidity Fee: Liquidity receiver cannot call this function.");
        uint256 initialBalance = address(this).balance;
        uint256 firstLiquidityHalf = amountToRedeem / 2;
        uint256 secondLiquidityHalf = amountToRedeem - firstLiquidityHalf;

        liquidityFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToRedeem);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            firstLiquidityHalf,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        (, , uint256 liquidity) = router.addLiquidityETH{
            value: address(this).balance - initialBalance
        }(
            address(this),
            secondLiquidityHalf,
            0,
            0,
            liquidityReceiver,
            block.timestamp + 1_200
        );

        return liquidity;
    }

    /* Check */

    function isTPC() external pure returns (bool) {
        return ISTPC;
    }

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(ZERO);
    }

    /* Update */

    function updateRouter(address newRouter) external authorized {
        require(address(router) != newRouter, "Update Router: This is the current router address.");
        address oldRouter = address(router);
        router = IRouter(newRouter);
        emit UpdateRouter(oldRouter, newRouter, block.timestamp);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
    }

    function updateMinSwap(uint256 newMinSwap) external authorized {
        require(minSwap != newMinSwap, "Update Min Swap: This is the current value of min swap.");
        uint256 oldMinSwap = minSwap;
        minSwap = newMinSwap;
        emit UpdateMinSwap(oldMinSwap, newMinSwap, block.timestamp);
    }

    function updateBuyFee(uint256 newLaunchpadFee, uint256 newLiquidityFee) external authorized {
        require(!isFeeLocked, "Update Buy Fee: All buy fees were locked and cannot be updated.");
        require(newLaunchpadFee + newLiquidityFee <= 1000, "Update Buy Fee: Total fees cannot exceed 10%.");
        buyLaunchpadFee = newLaunchpadFee;
        buyLiquidityFee = newLiquidityFee;
    }

    function updateSellFee(uint256 newLaunchpadFee, uint256 newLiquidityFee) external authorized {
        require(!isFeeLocked, "Update Sell Fee: All sell fees were locked and cannot be updated.");
        require(newLaunchpadFee + newLiquidityFee <= 1000, "Update Sell Fee: Total fees cannot exceed 10%.");
        sellLaunchpadFee = newLaunchpadFee;
        sellLiquidityFee = newLiquidityFee;
    }

    function updateTransferFee(uint256 newLaunchpadFee, uint256 newLiquidityFee) external authorized {
        require(!isFeeLocked, "Update Transfer Fee: All transfer fees were locked and cannot be updated.");
        require(newLaunchpadFee + newLiquidityFee <= 1000, "Update Transfer Fee: Total fees cannot exceed 10%.");
        transferLaunchpadFee = newLaunchpadFee;
        transferLiquidityFee = newLiquidityFee;
    }

    function updateFeeActive(bool newStatus) external authorized {
        require(isFeeActive != newStatus, "Update Fee Active: This is the current state for the fee.");
        bool oldStatus = isFeeActive;
        isFeeActive = newStatus;
        emit UpdateFeeActive(oldStatus, newStatus, block.timestamp);
    }

    function updateSwapEnabled(bool newStatus) external authorized {
        require(isSwapEnabled != newStatus, "Update Swap Enabled: This is the current state for the swap.");
        bool oldStatus = isSwapEnabled;
        isSwapEnabled = newStatus;
        emit UpdateSwapEnabled(oldStatus, newStatus, block.timestamp);
    }

    function updateLaunchpadReceiver(address newLaunchpadReceiver) external authorized {
        require(launchpadReceiver != newLaunchpadReceiver, "Update Launchpad Receiver: This is the current launchpad receiver address.");
        address oldLaunchpadReceiver = launchpadReceiver;
        launchpadReceiver = newLaunchpadReceiver;
        emit UpdateLaunchpadReceiver(oldLaunchpadReceiver, newLaunchpadReceiver, block.timestamp);
    }

    function updateLiquidityReceiver(address newLiquidityReceiver) external authorized {
        require(liquidityReceiver != newLiquidityReceiver, "Update Liquidity Receiver: This is the current liquidity receiver address.");
        address oldLiquidityReceiver = liquidityReceiver;
        liquidityReceiver = newLiquidityReceiver;
        emit UpdateLiquidityReceiver(oldLiquidityReceiver, newLiquidityReceiver, block.timestamp);
    }

    function setExcludeFromFees(address user, bool status) external authorized {
        require(isExcludeFromFees[user] != status, "Set Exclude From Fees: This is the current state for this address.");
        isExcludeFromFees[user] = status;
    }

    /* Fee */

    function takeBuyFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeTotal = buyLaunchpadFee + buyLiquidityFee;
        uint256 feeAmount = amount * feeTotal / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallyBuyFee(from, feeAmount, feeTotal);
        return newAmount;
    }

    function takeSellFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeTotal = sellLaunchpadFee + sellLiquidityFee;
        uint256 feeAmount = amount * feeTotal / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallySellFee(from, feeAmount, feeTotal);
        return newAmount;
    }

    function takeTransferFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeTotal = transferLaunchpadFee + transferLiquidityFee;
        uint256 feeAmount = amount * feeTotal / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallyTransferFee(from, feeAmount, feeTotal);
        return newAmount;
    }

    function tallyBuyFee(address from, uint256 amount, uint256 fee) internal swapping {
        uint256 collectLaunchpad = amount * buyLaunchpadFee / fee;
        uint256 collectLiquidity = amount - collectLaunchpad;
        tallyCollection(collectLaunchpad, collectLiquidity, amount);
        
        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function tallySellFee(address from, uint256 amount, uint256 fee) internal swapping {
        uint256 collectLaunchpad = amount * sellLaunchpadFee / fee;
        uint256 collectLiquidity = amount - collectLaunchpad;
        tallyCollection(collectLaunchpad, collectLiquidity, amount);
        
        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function tallyTransferFee(address from, uint256 amount, uint256 fee) internal swapping {
        uint256 collectLaunchpad = amount * transferLaunchpadFee / fee;
        uint256 collectLiquidity = amount - collectLaunchpad;
        tallyCollection(collectLaunchpad, collectLiquidity, amount);

        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function tallyCollection(uint256 collectLaunchpad, uint256 collectLiquidity, uint256 amount) internal swapping {
        launchpadFeeCollected += collectLaunchpad;
        liquidityFeeCollected += collectLiquidity;
        totalFeeCollected += amount;

    }

    function autoRedeem(uint256 amountToRedeem) public swapping returns (uint256) {  
        require(msg.sender != liquidityReceiver, "Auto Redeem: Cannot use liquidity receiver to trigger this.");
        uint256 launchpadToRedeem = launchpadFeeCollected - launchpadFeeRedeemed;
        uint256 totalToRedeem = totalFeeCollected - totalFeeRedeemed;

        uint256 initialBalance = address(this).balance;
        uint256 launchpadFeeDistribution = amountToRedeem * launchpadToRedeem / totalToRedeem;
        uint256 liquidityFeeDistribution = amountToRedeem - launchpadFeeDistribution;
        uint256 firstLiquidityHalf = liquidityFeeDistribution / 2;
        uint256 secondLiquidityHalf = liquidityFeeDistribution - firstLiquidityHalf;
        uint256 redeemAmount = amountToRedeem;

        launchpadFeeRedeemed += launchpadFeeDistribution;
        liquidityFeeRedeemed += liquidityFeeDistribution;
        totalFeeRedeemed += amountToRedeem;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), redeemAmount);
    
        emit AutoRedeem(launchpadFeeDistribution, liquidityFeeDistribution, redeemAmount, block.timestamp);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            launchpadFeeDistribution,
            0,
            path,
            launchpadReceiver,
            block.timestamp
        );

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            firstLiquidityHalf,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        (, , uint256 liquidity) = router.addLiquidityETH{
            value: address(this).balance - initialBalance
        }(
            address(this),
            secondLiquidityHalf,
            0,
            0,
            liquidityReceiver,
            block.timestamp + 1_200
        );
        
        return liquidity;
    }

    /* Buyback */

    function triggerZeusBuyback(uint256 amount) external authorized {
        buyTokens(amount, DEAD);
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        require(msg.sender != DEAD, "Buy Tokens: Dead address cannot call this function.");
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    /* ERC20 Standard */

    function name() external view virtual override returns (string memory) {
        return NAME;
    }
    
    function symbol() external view virtual override returns (string memory) {
        return SYMBOL;
    }
    
    function decimals() external view virtual override returns (uint8) {
        return DECIMALS;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address provider = _msgSender();
        return _transfer(provider, to, amount);
    }
    
    function allowance(address provider, address spender) public view virtual override returns (uint256) {
        return _allowances[provider][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address provider = _msgSender();
        _approve(provider, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        return _transfer(from, to, amount);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address provider = _msgSender();
        _approve(provider, spender, allowance(provider, spender) + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address provider = _msgSender();
        uint256 currentAllowance = allowance(provider, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(provider, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _approve(address provider, address spender, uint256 amount) internal virtual {
        require(provider != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[provider][spender] = amount;
        emit Approval(provider, spender, amount);
    }
    
    function _spendAllowance(address provider, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(provider, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(provider, spender, currentAllowance - amount);
            }
        }
    }

    /* Additional */

    function _basicTransfer(address from, address to, uint256 amount ) internal returns (bool) {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }
    
    /* Overrides */
 
    function _transfer(address from, address to, uint256 amount) internal virtual returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (inSwap || isExcludeFromFees[from]) {
            return _basicTransfer(from, to, amount);
        }

        if (from != pair && isSwapEnabled && totalFeeCollected - totalFeeRedeemed >= minSwap) {
            autoRedeem(minSwap);
        }

        uint256 newAmount = amount;

        if (isFeeActive && !isExcludeFromFees[from]) {
            newAmount = _beforeTokenTransfer(from, to, amount);
        }

        require(_balances[from] >= newAmount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = _balances[from] - newAmount;
            _balances[to] += newAmount;
        }

        emit Transfer(from, to, newAmount);

        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal swapping virtual returns (uint256) {
        if (from == pair && (buyLaunchpadFee + buyLiquidityFee > 0)) {
            return takeBuyFee(from, amount);
        }
        if (to == pair && (sellLaunchpadFee + sellLiquidityFee > 0)) {
            return takeSellFee(from, amount);
        }
        if (from != pair && to != pair && (transferLaunchpadFee + transferLiquidityFee > 0)) {
            return takeTransferFee(from, amount);
        }
        return amount;
    }

}