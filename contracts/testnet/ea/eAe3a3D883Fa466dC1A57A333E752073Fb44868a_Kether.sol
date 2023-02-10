// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./libraries/SafeMath.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IDEXFactory.sol";
import "./interfaces/IDEXRouter.sol";
import "./Auth.sol";
import "./DividendDistributor.sol";

contract Kether is IBEP20, Auth {
    using SafeMath for uint256;
    
    /* Variables */
    string private s_name;
    string private s_symbol;
    uint8 private immutable i_decimals;
    uint256 private s_totalSupply;
    
    address private immutable i_wbnb;
    address private immutable i_reward;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    uint256 private s_maxTxAmount;
    uint256 private s_maxWalletToken;

    mapping(address => uint256) private s_balances;
    mapping(address => mapping (address => uint256)) private s_allowances;

    bool private blacklistMode;
    mapping(address => bool) public isBlacklisted;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isTimelockExempt;
    mapping(address => bool) public isDividendExempt;

    uint256 public liquidityFee;
    uint256 public reflectionFee;
    uint256 public marketingFee;
    uint256 public teamFee;
    uint256 public devFee;
    uint256 public burnFee;
    uint256 public totalFee;
    
    uint256 private s_feeDenominator = 100;
    uint256 private s_sellMultiplier = 100;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public teamFeeReceiver;
    address public burnFeeReceiver;
    address public devFeeReceiver;

    uint256 public targetLiquidity = 95;
    uint256 public targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool private tradingOpen;

    DividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool private buyCooldownEnabled;
    uint8 private s_cooldownTimerInterval = 5;
    mapping (address => uint) private s_cooldownTimer;

    bool private swapEnabled = true;
    uint256 private s_swapThreshold;
    bool private inSwap;
    
    /* Modifiers */
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    /* Events */
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    
    /* Functions */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 intSupply,
        address routerAddress,
        address rewardAddress,
        uint256[] memory fees,
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver,
        address _teamFeeReceiver,
        address _devFeeReceiver,
        address _burnFeeReceiver,
        bool _blacklistMode,
        bool _tradingOpen,
        bool _buyCooldownEnabled
    ) Auth(msg.sender) {
        s_name = _name;
        s_symbol = _symbol;
        i_decimals = _decimals;
        
        s_totalSupply = intSupply * 10**_decimals;
        s_maxTxAmount = s_totalSupply / 100;
        s_maxWalletToken = s_totalSupply / 50;
        
        router = IDEXRouter(routerAddress);

        i_wbnb = router.WETH();
        i_reward = rewardAddress;
        
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        s_allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor(address(msg.sender), rewardAddress);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        
        liquidityFee = fees[0];
        reflectionFee = fees[1];
        marketingFee = fees[2];
        teamFee = fees[3];
        devFee = fees[4];
        burnFee = fees[5];
        totalFee = marketingFee + reflectionFee + liquidityFee + teamFee + burnFee + devFee;
        
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        teamFeeReceiver = _teamFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
        burnFeeReceiver = _burnFeeReceiver;
        
        s_swapThreshold = s_totalSupply * 10 / 10000;
        
        blacklistMode = _blacklistMode;
        tradingOpen = _tradingOpen;
        buyCooldownEnabled = _buyCooldownEnabled;

        s_balances[msg.sender] = s_totalSupply;
        emit Transfer(address(0), msg.sender, s_totalSupply);
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        s_allowances[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns(bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns(bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) external override returns(bool) {
        if(s_allowances[sender][msg.sender] != uint256(-1)){
            s_allowances[sender][msg.sender] = s_allowances[sender][msg.sender].sub(
                amount, 
                "Insufficient Allowance"
            );
        }
        
        return _transferFrom(sender, recipient, amount);
    }
    
    function revealIdentity(string memory _newName, string memory _newSymbol) external onlyOwner() {
        s_name = _newName;
        s_symbol = _newSymbol;
    }
    
    function setMaxWalletPercentBase1000(uint256 maxWalletPercentBase1000) external onlyOwner() {
        s_maxWalletToken = (s_totalSupply * maxWalletPercentBase1000) / 1000;
    }
    
    function setMaxTxPercentBase1000(uint256 maxTXPercentageBase1000) external onlyOwner() {
        s_maxTxAmount = (s_totalSupply * maxTXPercentageBase1000) / 1000;
    }
    
    function setMaxWallet(uint256 amount) external authorized {
        s_maxWalletToken = amount;
    }
    
    function setTxLimit(uint256 amount) external authorized {
        s_maxTxAmount = amount;
    }

    function _transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) internal returns(bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
        }
        
        // blacklist
        if(blacklistMode){
            require(!isBlacklisted[sender] && !isBlacklisted[recipient],"Blacklisted");    
        }
        
        if(
            !authorizations[sender] && 
            recipient != address(this) && 
            recipient != address(DEAD) && 
            recipient != pair &&
            recipient != marketingFeeReceiver && 
            recipient != teamFeeReceiver && 
            recipient != autoLiquidityReceiver && 
            recipient != burnFeeReceiver
        ){
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= s_maxWalletToken,
                "Total Holding is currently limited, you can not buy that much."
            );
        }
        
        if(
            sender == pair &&
            buyCooldownEnabled &&
            !isTimelockExempt[recipient]
        ){
            require(
                s_cooldownTimer[recipient] < block.timestamp,
                "Please wait for 1min between two buys"
            );
            s_cooldownTimer[recipient] = block.timestamp + s_cooldownTimerInterval;
        }
        
        // checks max transaction limit
        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }
        
        // exchange tokens
        s_balances[sender] = s_balances[sender].sub(amount, "Insufficient Balance");
        
        uint256 amountReceived = 
            (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? 
            amount : 
            takeFee(sender, amount, (recipient == pair));
        
        s_balances[recipient] = s_balances[recipient].add(amountReceived);
        
        // dividend tracker
        if(!isDividendExempt[sender]){
            try distributor.setShare(sender, s_balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]){
            try distributor.setShare(recipient, s_balances[recipient]) {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
   
    function _basicTransfer(
        address sender, 
        address recipient, 
        uint256 amount
    ) internal returns(bool) {
        s_balances[sender] = s_balances[sender].sub(amount, "Insufficient Balance");
        s_balances[recipient] = s_balances[recipient].add(amount);
        
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount, bool isSell) internal returns(uint256) {
        uint256 multiplier = isSell ? s_sellMultiplier : 100;
        uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(s_feeDenominator * 100);

        uint256 burnTokens = feeAmount.mul(burnFee).div(totalFee);
        uint256 contractTokens = feeAmount.sub(burnTokens);
        
        s_balances[address(this)] = s_balances[address(this)].add(contractTokens);
        s_balances[burnFeeReceiver] = s_balances[burnFeeReceiver].add(burnTokens);
        
        emit Transfer(sender, address(this), contractTokens);
        
        if(burnTokens > 0){
            emit Transfer(sender, burnFeeReceiver, burnTokens);    
        }
        
        return amount.sub(feeAmount);
    }

    function clearStuckBalanceToMarketing(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }

    function clearStuckBalanceToSender(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
    }

    function setSellMultiplier(uint256 _multiplier) external onlyOwner {
        s_sellMultiplier = _multiplier;        
    }

    // switch trading
    function tradingStatus(bool _status) public onlyOwner {
        tradingOpen = _status;
    }

    // enable cooldown between trades
    function setCooldown(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        s_cooldownTimerInterval = _interval;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = 
            isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 
            0 : 
            liquidityFee;
        uint256 amountToLiquify = s_swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = s_swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = i_wbnb;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
       
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBTeam = amountBNB.mul(teamFee).div(totalBNBFee);
        uint256 amountBNBDev = amountBNB.mul(devFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{
            value: amountBNBMarketing, 
            gas: 30000
        }("");
        (tmpSuccess,) = payable(teamFeeReceiver).call{value: amountBNBTeam, gas: 30000}("");
        (tmpSuccess,) = payable(devFeeReceiver).call{value: amountBNBDev, gas: 30000}("");
       
        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        
        isDividendExempt[holder] = exempt;
        
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, s_balances[holder]);
        }
    }

    function enableBlacklist(bool _status) public onlyOwner {
        blacklistMode = _status;
    }

    function manageBlacklist(address[] calldata addresses, bool status) public onlyOwner {
        for(uint256 i; i < addresses.length; ++i){
            isBlacklisted[addresses[i]] = status;
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt) external authorized {
        isTimelockExempt[holder] = exempt;
    }

    function setFees(
        uint256 _liquidityFee, 
        uint256 _reflectionFee, 
        uint256 _marketingFee, 
        uint256 _teamFee, 
        uint256 _devFee, 
        uint256 _burnFee, 
        uint256 _feeDenominator
    ) external authorized {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        teamFee = _teamFee;
        devFee = _devFee;
        burnFee = _burnFee;
        
        totalFee = _liquidityFee + _reflectionFee + _marketingFee + _teamFee + _burnFee + _devFee;
        s_feeDenominator = _feeDenominator;
        
        require(totalFee < s_feeDenominator/2, "Fees cannot be more than 50%");
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver, 
        address _marketingFeeReceiver, 
        address _teamFeeReceiver,
        address _devFeeReceiver,
        address _burnFeeReceiver
    ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        teamFeeReceiver = _teamFeeReceiver;
        burnFeeReceiver = _burnFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        s_swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(
        uint256 _minPeriod, 
        uint256 _minDistribution
    ) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        
        distributorGas = gas;
    }

    /* Rewards Distribution */
    function multiTransfer(
        address from, 
        address[] calldata addresses, 
        uint256[] calldata tokens
    ) external onlyOwner {
        require(addresses.length < 501,"GAS Error: max airdrop limit is 500 addresses");
        require(addresses.length == tokens.length,"Mismatch between Address and token count");

        uint256 SCCC = 0;

        for(uint i=0; i < addresses.length; i++){
            SCCC = SCCC + tokens[i];
        }

        require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(from,addresses[i],tokens[i]);
            if(!isDividendExempt[addresses[i]]) {
                try distributor.setShare(addresses[i], s_balances[addresses[i]]) {} catch {}
            }
        }

        // dividend tracker
        if(!isDividendExempt[from]) {
            try distributor.setShare(from, s_balances[from]) {} catch {}
        }
    }

    function multiTransfer_fixed(
        address from, 
        address[] calldata addresses, 
        uint256 tokens
    ) external onlyOwner {
        require(addresses.length < 801,"GAS Error: max airdrop limit is 800 addresses");

        uint256 SCCC = tokens * addresses.length;

        require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(from,addresses[i],tokens);
            if(!isDividendExempt[addresses[i]]) {
                try distributor.setShare(addresses[i], s_balances[addresses[i]]) {} catch {}
            }
        }

        // dividend tracker
        if(!isDividendExempt[from]) {
            try distributor.setShare(from, s_balances[from]) {} catch {}
        }
    }
    
    /* View Functions */
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= s_maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    function shouldTakeFee(address sender) internal view returns(bool) {
        return !isFeeExempt[sender];
    }
    function shouldSwapBack() internal view returns(bool) {
        return 
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            s_balances[address(this)] >= s_swapThreshold;
    }
    
    function name() external view override returns(string memory) { return s_name; }
    function symbol() external view override returns(string memory) { return s_symbol; }
    function decimals() external view override returns(uint8) { return i_decimals; }
    function totalSupply() external view override returns(uint256) { return s_totalSupply; }
    
    function getOwner() external view override returns(address) { return owner; }
    function getMaxTxAmount() external view returns(uint256) { return s_maxTxAmount; }
    function getMaxWalletToken() external view returns(uint256) { return s_maxWalletToken; }
    function getFeeDenominator() external view returns(uint256) { return s_feeDenominator; }
    function getSellMultiplier() external view returns(uint256) { return s_sellMultiplier; }
    function getSwapThreshold() external view returns(uint256) { return s_swapThreshold; }
    function getCooldownTimerInterval() external view returns(uint8) { 
        return s_cooldownTimerInterval; 
    }
    
    function isTradingOpen() external view returns(bool) { return tradingOpen; }
    function isBuyCooldownEnabled() external view returns(bool) { return buyCooldownEnabled; }
    function isSwapEnabled() external view returns(bool) { return swapEnabled; }
    function isBlacklistMode() external view returns(bool) { return blacklistMode; }
    
    function allowance(address holder, address spender) external view override returns(uint256) { 
        return s_allowances[holder][spender]; 
    }  
    function balanceOf(address account) public view override returns(uint256) { 
        return s_balances[account]; 
    }
    function cooldownTime(address holder) external view returns(uint) {
        return s_cooldownTimer[holder];
    }
    
    function getCirculatingSupply() public view returns(uint256) {
        return s_totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    function getLiquidityBacking(uint256 accuracy) public view returns(uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }
    
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns(bool) {
        return getLiquidityBacking(accuracy) > target;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(
        uint256 a, 
        uint256 b, 
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(
        uint256 a, 
        uint256 b, 
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

interface IBEP20 {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

interface IDEXRouter {
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./libraries/SafeMath.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IDividendDistributor.sol";

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;
    address public _owner;
    address public _rewardAddress;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 RWRD = IBEP20(_rewardAddress);

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 18;

    uint256 public minPeriod = 45 * 60;
    uint256 public minDistribution = 1 * (10 ** 16);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token || msg.sender == _owner); _;
    }

    constructor (address _tokenowner, address rewardAddress) {
        _token = msg.sender;
        _owner = _tokenowner;
        _rewardAddress = rewardAddress;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        totalDividends = totalDividends.add(msg.value);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
   
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);

            payable(shareholder).transfer(amount);
           
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
   
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}