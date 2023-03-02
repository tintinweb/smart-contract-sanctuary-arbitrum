/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

//SPDX-License-Identifier: MIT

//email - [email protected]
//website - https://zetas2099.eth.limo/
//twitter - https://twitter.com/zetas2099
//telegram - https://t.me/zetas2099
//medium - https://medium.com/@zetas2099/inception-bbe8b398081f

pragma solidity ^0.8.17;

interface ERC20 {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

abstract contract Ownable {

    address internal owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner"); 
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

interface Whitelist {
    function getWLStatus(address sender, address recipient) external view returns (bool);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDEXRouter {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract Zetas2099 is ERC20, Ownable {

    // Events
    event SetMaxWallet(uint256 maxWalletToken);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold);
    event SetIsFeeExempt(address holder, bool enabled);
    event SetIsTxLimitExempt(address holder, bool enabled);
    event StuckBalanceSent(uint256 amountETH, address recipient);
    event Mint(address indexed account, uint256 indexed amount);

    // Mappings
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;

    // Token info
    string constant _name = "Zetas 2099";
    string constant _symbol = "LIX";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 10000000 * (10 ** _decimals); 
    uint256 public launchStage;

    // Max wallet
    uint256 public _maxWalletSize = (_totalSupply * 10) / 1000;
    uint256 public _maxTxSize = (_totalSupply * 10) / 1000;

    // Tax amounts
    uint256 public DevFee = 10;
    uint256 public Treasury1Fee = 10;
    uint256 public Treasury2Fee = 10;
    uint256 public Team1Fee = 10;
    uint256 public Team2Fee = 10;
    uint256 public LiquidityFee = 20;
    uint256 public TotalTax = DevFee + Treasury1Fee + Treasury2Fee + Team1Fee + Team2Fee + LiquidityFee;

    // Tax wallets
    address DevWallet;
    address Treasury1Wallet;
    address Treasury2Wallet;
    address Team1Wallet;
    address Team2Wallet;

    // Contracts
    IDEXRouter public router;
    address public pair;
    Whitelist public whitelist;
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 10000;

    bool public isTradingEnabled = false;
    address public tradingEnablerRole;
    uint256 public tradingTimestamp;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor(address _router, address _whitelist) Ownable(msg.sender) {

        router = IDEXRouter(_router);
        _allowances[address(this)][address(router)] = type(uint256).max;
        whitelist = Whitelist(_whitelist);

        address _owner = owner;
        DevWallet = msg.sender;

        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;

        tradingEnablerRole = _owner;


        _balances[msg.sender] = _totalSupply * 100 / 100;

        emit Transfer(address(0), msg.sender, _totalSupply * 100 / 100);

    }

    receive() external payable { }

// Basic Internal Functions

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    ////////////////////////////////////////////////
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function getPair() public onlyOwner {
        pair = IDEXFactory(router.factory()).getPair(address(this), router.WETH());
        if (pair == address(0)) {pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());}
    }

    function renounceTradingEnablerRole() public {
        require(tradingEnablerRole == msg.sender, 'incompatible role!');
        tradingEnablerRole = address(0x0);
    }

    function setIsTradingEnabled(bool _isTradingEnabled) public {
        require(tradingEnablerRole == msg.sender, 'incompatible role!');
        isTradingEnabled = _isTradingEnabled;
        tradingTimestamp = block.timestamp;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(inSwap){ return _basicTransfer(sender, recipient, amount);}

        require(isFeeExempt[sender] || isFeeExempt[recipient] || (isTradingEnabled && (block.timestamp >= tradingTimestamp + 900)
            || whitelist.getWLStatus(sender, recipient)), "cant trade yet");

        if (sender != owner && recipient != owner && recipient != DEAD && recipient != pair && sender != Team1Wallet) {
            require(isTxLimitExempt[recipient] || (amount <= _maxTxSize && 
                _balances[recipient] + amount <= _maxWalletSize), "tx limit");
        }

        if(shouldSwapBack()){swapBack();}

        _balances[sender] = _balances[sender] - amount;
        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

// Internal Functions

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
   
        uint256 feeAmount = 0;

        if (sender == pair && recipient != pair) {
            feeAmount = amount * (TotalTax) / 1000;
        } if (sender != pair && recipient == pair) {
            feeAmount = amount * (TotalTax) / 1000;
        }

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + (feeAmount);
            emit Transfer(sender, address(this), feeAmount);            
        }

        return amount - (feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function addLiquidity(uint256 _tokenBalance, uint256 _ETHBalance) private {
        if(_allowances[address(this)][address(router)] < _tokenBalance){_allowances[address(this)][address(router)] = _tokenBalance;}
        router.addLiquidityETH{value: _ETHBalance}(address(this), _tokenBalance, 0, 0, DevWallet, block.timestamp + 5 minutes);
    }

    function getFeeRates() view internal returns(uint256 devFee, uint256 treasury1Fee, 
        uint256 treasury2Fee, uint256 team1Fee, uint256 team2Fee) {

        uint256 currentBalance = address(this).balance;
        uint256 totalFees = TotalTax - LiquidityFee;
        devFee = currentBalance * (DevFee) / totalFees;
        treasury1Fee = currentBalance * (Treasury1Fee) / totalFees;
        treasury2Fee = currentBalance * (Treasury2Fee) / totalFees;
        team1Fee = currentBalance * (Team1Fee) / totalFees;
        team2Fee = currentBalance * (Team2Fee) / totalFees;

    }

    function sendFees() internal returns(uint256 devFee, uint256 marketingFee, uint256 treasuryFee) {

        (uint256 devFee, uint256 treasury1Fee, uint256 treasury2Fee, uint256 team1Fee, uint256 team2Fee) = getFeeRates();

        (bool success1, /**/) = payable(DevWallet).call{value: devFee, gas: 30000}("");
        (bool success2, /**/) = payable(Treasury1Wallet).call{value: treasury1Fee, gas: 30000}("");
        (bool success3, /**/) = payable(Treasury2Wallet).call{value: treasury2Fee, gas: 30000}("");
        (bool success4, /**/) = payable(Team1Wallet).call{value: team1Fee, gas: 30000}("");
        (bool success5, /**/) = payable(Team2Wallet).call{value: team2Fee, gas: 30000}("");

        require(success1 && success2 && success3 && success4 && success5, 'cannot send');

    }

    function swapBack() internal swapping {

        uint256 amountToLiq = balanceOf(address(this)) * (LiquidityFee) / (2 * TotalTax);
        uint256 amountToSwap = balanceOf(address(this)) - amountToLiq;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

        if (amountToLiq > 0) {
            addLiquidity(amountToLiq, address(this).balance * (LiquidityFee) / (2 * TotalTax - LiquidityFee));
        }
    
        sendFees();
    
    }

// In-game dispenser functions
    mapping(address => bool) dispenserAddresses;

    //Mint and burn to be used by dispensers only!
    modifier onlyDispenser() {
        require(dispenserAddresses[msg.sender] == true, "Caller is not dispenser");
        _;
    }

    function getDispenser(address dispenser) view public returns(bool) {
        return dispenserAddresses[dispenser];
    }

    function setDispenser(address dispenser, bool permitted) external onlyOwner {
        dispenserAddresses[dispenser] = permitted;
    }

    function mint(address to, uint256 amount) external onlyDispenser {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "Mint to 0x0");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Mint(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) external onlyDispenser returns(bool _success){
        _success = _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual returns(bool){
        require(account != address(0), "Burn from 0x0");

        require(_balances[account] >= amount, "Insufficient balance");
        unchecked {
            _balances[account] -= amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
        return true;
    }

// Tax and Tx functions
    function setMax(uint256 _maxWalletSize_, uint256 _maxTxSize_) external onlyOwner {
        require(_maxWalletSize_ >= _totalSupply / 1000 && _maxTxSize_ >= _totalSupply / 1000, "max");
        _maxWalletSize = _maxWalletSize_;
        _maxTxSize = _maxTxSize_;
        emit SetMaxWallet(_maxWalletSize);
    }

    function setTaxExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit SetIsFeeExempt(holder, exempt);
    }

    function setTxExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
        emit SetIsTxLimitExempt(holder, exempt);
    }

    function setTaxes(uint256 _DevFee, uint256 _Treasury1Fee, uint256 _Treasury2Fee, uint256 _Team1Fee, 
        uint256 _Team2Fee, uint256 _LiquidityFee) external onlyOwner {

        uint256 DevFee = _DevFee;
        uint256 Treasury1Fee = _Treasury1Fee;
        uint256 Treasury2Fee = _Treasury2Fee;
        uint256 Team1Fee = _Team1Fee;
        uint256 Team2Fee = _Team2Fee;
        uint256 LiquidityFee = _LiquidityFee;

        uint256 TotalTax = DevFee + Treasury1Fee + Treasury2Fee + Team1Fee + Team2Fee + LiquidityFee;
        require(TotalTax <= 300, 'tax too high');

    }

    function setTaxWallets(address _DevWallet, address _Treasury1Wallet, address _Treasury2Wallet, 
        address _Team1Wallet, address _Team2Wallet) external onlyOwner {

        DevWallet = _DevWallet;
        Treasury1Wallet = _Treasury1Wallet;
        Treasury2Wallet = _Treasury2Wallet;
        Team1Wallet = _Team1Wallet;
        Team2Wallet = _Team2Wallet;

    }

    function getTaxWallets() view public returns(address,address,address,address,address) {
        return (DevWallet, Treasury1Wallet, Treasury2Wallet, Team1Wallet, Team2Wallet);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount >= 1, "zero");
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit SetSwapBackSettings(swapEnabled, swapThreshold);
    }

    function initSwapBack() public onlyOwner {
        swapBack();
    }

    function clearETH() external {

        require(DevWallet == msg.sender, 'dev');
        uint256 _ethBal = address(this).balance;
        if (_ethBal > 0) {
            payable(DevWallet).transfer(_ethBal);
        }

    }

    function clearToken(address _token) external {
        require(DevWallet == msg.sender, 'dev');
        ERC20(_token).transfer(DevWallet, ERC20(_token).balanceOf(address(this)));
    }

    function getSelfAddress() public view returns(address) {
        return address(this);
    }

}