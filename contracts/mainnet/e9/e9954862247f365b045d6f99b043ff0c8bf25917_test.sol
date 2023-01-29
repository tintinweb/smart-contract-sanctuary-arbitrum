/**
 *Submitted for verification at Arbiscan on 2023-01-29
*/

pragma solidity ^0.8.0;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Check if address is owner
    */
    
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Removes Old Owner Authorization.
     */

    function transferOwnership(address payable adr) public onlyOwner {
        authorizations[owner] = false;
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
     function createPair(address tokenA, address tokenB) external returns (address pair);
     function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDEXRouter {
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
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin, 
        uint amountBMin, 
        address to, 
        uint deadline) 
    external returns (uint amountA, uint amountB, uint liquidity);
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin,address[] calldata path,address to,uint deadline) external payable;
}

interface IBank {
    function setBankRules(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function setOnlyContract(address contractAddress) external;
    function claimRewards() external;
    function getRewards(address shareholder) external view returns (uint256);
    function getTotalRewards() external view returns (uint256);
    function getTotalDistributed() external view returns (uint256);
}

interface iWhiteList {
          function addWhiteList(address[] calldata toAddAddresses) external;
          function removeFromWhitelist(address[] calldata toRemoveAddresses) external;
          function checkWhiteList(address checkAddress) external;         
}

contract test is IERC20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address reflections = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // Goblin 0xfD559867B6d3445F9589074C3AC46418fDFffDA4
    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "test";
    string constant _symbol = "test";
    uint8 constant _decimals = 6;

    //uint256 _totalSupply = 1_000_000_000_000_000 * (10 ** _decimals);
    uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply; // Max Tx = Unlimited // Original = _totalSupply.div(200); // 0.55%
    uint256 public _maxWallet = _totalSupply.div(100); // 1% Max Wallet // For White List // 2% Max Wallet After WhiteList Disabled

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) public _isFree;

    uint256 liquidityFee = 100;
    uint256 reflectionFee = 500;
    uint256 marketingFee = 200;
    uint256 totalFee = 800;
    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 10;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    IBank bank;
    address public bankAddress;

    iWhiteList whitelist;
    address public whilistAddress;

    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    bool public whiteListEnabled = true;

    uint256 public swapThreshold = _totalSupply / 5000; // 0.0025%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address initBank, address initWhiteList) Auth(msg.sender) {

        address _router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; 

        
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        WETH = router.WETH();  

        _allowances[address(this)][address(router)] = _totalSupply;

        bank = IBank(initBank);
        bankAddress = address(initBank);
        bank.setOnlyContract(address(this));

        whitelist = iWhiteList(initWhiteList);  // only current owner can modify (disabled on whitelist disabled)
        whilistAddress = address(initWhiteList);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

        approve(_router, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    

    receive() external payable { }

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
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function disableWhiteLIst() external onlyOwner {
        whiteListEnabled = false;
        _maxWallet = _totalSupply.div(50); // 2% Max Wallet 
    }

    function addWhiteList(address[] calldata toAddAddresses) external onlyOwner 
    {
        whitelist.addWhiteList(toAddAddresses);
    }
          
    function removeFromWhitelist(address[] calldata toRemoveAddresses) external onlyOwner
    {
        whitelist.removeFromWhitelist(toRemoveAddresses);
    }


    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        address routerAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // 
        
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
         
        // Checks if the holder is buying or selling
        bool isBuy= sender== pair|| sender == routerAddress; // sender (to) is router therefore sender is buying
        bool isSell= recipient== pair|| recipient == routerAddress; // recipient (from) is router therefore recipient is selling

        // WhiteList Check if enabled - Disabled on whiteListEnabled = false.
        if (whiteListEnabled == true && isBuy == true) { whitelist.checkWhiteList(recipient);}
        
        // Check Max Transaction
        checkTxLimit(sender, amount);
        
        // Max wallet check excluding pair and router -> for buyers
        if (!isSell && !_isFree[recipient]){
            require((_balances[recipient] + amount) < _maxWallet, "Max wallet has been triggered");
        }
        
        // No swapping on buy
        if (isSell) { if (shouldSwapBack()) {swapBack();} }
        
        // Launch Check
        if(!launched() && recipient == pair) { 
            require(_balances[sender] > 0); 
            launch(); 
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        // buyers, take fee check
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try bank.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try bank.setShare(recipient, _balances[recipient]) {} catch {} }

        try bank.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
//        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return totalFee; }
        if(selling){ return totalFee; }
        return totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHReflection = amountETH.mul(reflectionFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);

        try bank.deposit{value: amountETHReflection}() {} catch {}
        payable(marketingFeeReceiver).transfer(amountETHMarketing);


        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
            

    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function claimRewards() external {
        bank.claimRewards();      
    }

    function getRewards(address shareholder) external view returns (uint256) {
        bank.getRewards(shareholder);
    }

    function getTotalRewards() external view returns (uint256) {
        return bank.getTotalRewards();
    }

    function getTotalDistributed() external view returns (uint256) {
        return bank.getTotalDistributed();
    }
    
    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public authorized {
        require(launchedAt == 0, "Already launched");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }
    
    function setMaxWallet(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            bank.setShare(holder, 0);
        }else{
            bank.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }
    
    function setFree(address holder) public onlyOwner {
        _isFree[holder] = true;
    }
    
    function unSetFree(address holder) public onlyOwner {
        _isFree[holder] = false;
    }
    
    function checkFree(address holder) public view onlyOwner returns(bool){
        return _isFree[holder];
    }

    function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee) external authorized {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee);
        require(totalFee < feeDenominator/4);
    }


    function getFees()  public view returns(string memory , uint256, string memory , uint256, string memory , uint256) {
        return ('Liquidity Fee: ', liquidityFee,'Marketing Fee: ',marketingFee, 'Reflections Fee:', reflectionFee);
    }

    function setWallets(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setBankRules(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        bank.setBankRules(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountWETH, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}