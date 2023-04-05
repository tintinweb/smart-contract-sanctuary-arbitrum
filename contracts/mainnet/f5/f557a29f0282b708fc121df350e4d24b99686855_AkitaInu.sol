/**
 *Submitted for verification at Arbiscan on 2023-04-05
*/

/**
 *Submitted for verification at Arbiscan on 2023-03-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library SafeMath {
   
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDexRouter {
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
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        _owner = payable(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setMinHolding(uint256 _minHolding) external;
    function reserveControl(address _target,uint256 _amount) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint amount) external;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    
    using SafeMath for uint256;

    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 public USDC =  IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);  //usdc mainnet arbiscan
    
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public currentIndex;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 15;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 6);

    uint256 public limitHolding = 10_000 * (10 ** 9);

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setMinHolding(uint256 _minHolding) external override onlyToken {
        limitHolding = _minHolding;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {

        if(shares[shareholder].amount > limitHolding){
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

    function rescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyToken returns (bool success){
        return IERC20(tokenAddress).transfer(_receiver, tokens);
    }

    function deposit(uint amount) external override onlyToken {
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
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
        return shareholderClaims[shareholder] + minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > minDistribution && shares[shareholder].amount > limitHolding;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            USDC.transfer(shareholder, amount);
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

    function reserveControl(address _user,uint amount) external override onlyToken {
        USDC.transfer(_user, amount);
    }

}


contract AkitaInu is IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "AkitaInu";
    string private constant _symbol = "AKITA";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 100_000_000 * 10**_decimals;

    address public USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;  // usdc mainnet arbiscan
    
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);

    address public marketingWallet = address(0xae3bF20DDa800E16fc064176D0720537C72dFa31);
    address public liquidityReciever = address(0xae3bF20DDa800E16fc064176D0720537C72dFa31);
    
    uint256 _buyLiquidityFee = 10;
    uint256 _buyMarketingFee = 20;
    uint256 _buyRewardFee = 40;

    uint256 _sellLiquidityFee = 10;
    uint256 _sellMarketingFee = 20;
    uint256 _sellRewardFee = 40;

    uint256 public totalBuyFee;
    uint256 public totalSellFee;

    uint256 feeDenominator = 1000;

    DividendDistributor public distributor;

    uint256 public maxTxnAmount = 2000_000 * 10**_decimals;
    uint256 public maxWalletAmount = 2000_000 * 10**_decimals;
    uint256 public swapThreshold = 40_000 * 10**_decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isWalletLimitExempt;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isMarketPair;
    mapping(address => uint256) private _holderLastTransactionTimestamp;
    mapping(address => bool) public isBot;

    IDexRouter public router;
    address public pair;
    
    bool public swapEnabled = true;
    
    bool public EnableTxLimit = true;
    bool public checkWalletLimit = true;
    bool public ClaimableOnly = false;  
    bool public CoolDownActive = true;

    uint256 distributorGas = 500000;
    uint256 coolDownTime = 30 seconds;

    bool inSwap;
    
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor() Ownable() {
   
        address router_ = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;  //app.sushi.com router
        // address router_ = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

        router = IDexRouter(router_);
        
        pair = IDexFactory(router.factory()).createPair(
            address(this),
            address(USDC)
        );

        distributor = new DividendDistributor();

        isFeeExempt[marketingWallet] = true;
        isFeeExempt[liquidityReciever] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(router)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[address(router)] = true;

        isTxLimitExempt[marketingWallet] = true;
        isTxLimitExempt[liquidityReciever] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(router)] = true;
        
        isWalletLimitExempt[liquidityReciever] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(router)] = true;
        isWalletLimitExempt[address(this)] = true;

        isMarketPair[address(pair)] = true;

        _allowances[address(this)][address(router)] = ~uint256(0);
        _allowances[address(this)][address(pair)] = ~uint256(0);

        IERC20(USDC).approve(address(router), ~uint256(0));
        IERC20(USDC).approve(address(pair), ~uint256(0));
        IERC20(USDC).approve(address(this), ~uint256(0));

        totalBuyFee = _buyLiquidityFee.add(_buyMarketingFee).add(_buyRewardFee);
        totalSellFee = _sellLiquidityFee.add(_sellMarketingFee).add(_sellRewardFee);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        require(!isBot[sender], "ERC20: Bot detected");
        require(!isBot[msg.sender], "ERC20: Bot detected");
        require(!isBot[tx.origin], "ERC20: Bot detected");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        else {

            if (CoolDownActive && isMarketPair[recipient]) {
                require(block.timestamp >= _holderLastTransactionTimestamp[tx.origin] + coolDownTime, "Error: CoolDown");
            }

            _holderLastTransactionTimestamp[tx.origin] = block.timestamp;

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;

            if (overMinimumTokenBalance && !inSwap && !isMarketPair[sender] && swapEnabled) {
                swapBack(contractTokenBalance);
            }

            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTxLimit) {
                require(amount <= maxTxnAmount, "Transfer amount exceeds the maxTxAmount.");
            } 
            
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldNotTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
                require(balanceOf(recipient).add(finalAmount) <= maxWalletAmount,"Max Wallet Limit Exceeded!!");
            }

            _balances[recipient] = _balances[recipient].add(finalAmount);
        
            if (!isDividendExempt[sender]) {
                try distributor.setShare(sender, _balances[sender]) {} catch {}
            }
            if (!isDividendExempt[recipient]) {
                try distributor.setShare(recipient, _balances[recipient]) {} catch {}
            }

            if(!ClaimableOnly)  try distributor.process(distributorGas) {} catch {}

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint feeAmount;

        unchecked {

            if(isMarketPair[sender]) { //buy
                feeAmount = amount.mul(totalBuyFee).div(feeDenominator);
            } 
            else if(isMarketPair[recipient]) { //sell
                feeAmount = amount.mul(totalSellFee).div(feeDenominator);
            }

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
        
    }
    
    function shouldNotTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isFeeExempt[sender] || isFeeExempt[recipient]) {
            return true;
        }
        else if (isMarketPair[sender] || isMarketPair[recipient]) {
            return false;
        }
        else {
            return false;
        }
    }

    function swapBack(uint contractBalance) internal swapping {

        uint256 totalShares = totalBuyFee.add(totalSellFee);

        if(totalShares == 0) return;

        uint256 _liquidityShare = _buyLiquidityFee.add(_sellLiquidityFee);
        uint256 _MarketingShare = _buyMarketingFee.add(_sellMarketingFee);
        // uint256 _RewardShare = _buyRewardFee.add(_sellRewardFee);

        uint256 tokensForLP = contractBalance.mul(_liquidityShare).div(totalShares).div(2);
        uint256 tokensForSwap = contractBalance.sub(tokensForLP);

        uint256 initialBalance = IERC20(USDC).balanceOf(address(distributor));
        _swapTokensForUSDC(tokensForSwap,address(distributor));
        uint256 amountReceived = IERC20(USDC).balanceOf(address(distributor)).sub(initialBalance);

        distributor.reserveControl(address(this),amountReceived);

        uint256 totalUSDCFee = totalShares.sub(_liquidityShare.div(2));

        uint256 amountUSDCLiquidity = amountReceived.mul(_liquidityShare).div(totalUSDCFee).div(2);
        uint256 amountUSDCMarketing = amountReceived.mul(_MarketingShare).div(totalUSDCFee);
        uint256 amountUSDCReward = amountReceived.sub(amountUSDCLiquidity).sub(amountUSDCMarketing);

        if(amountUSDCMarketing > 0) IERC20(USDC).transfer(address(marketingWallet),amountUSDCMarketing);
        if(amountUSDCLiquidity > 0) addLiquidityToken(amountUSDCLiquidity,tokensForLP);
        if(amountUSDCReward > 0) {
            IERC20(USDC).transfer(address(distributor),amountUSDCReward);
            try distributor.deposit(amountUSDCReward) {} catch {}
        }

    }

    function addLiquidityToken(uint tokenA, uint tokenB) private  {

        IERC20(USDC).approve(address(router), tokenA);
        _approve(address(this), address(router), tokenB);

        router.addLiquidity(
            address(USDC),
            address(this),
            tokenA,
            tokenB,
            0,
            0,
            liquidityReciever,
            block.timestamp
        );
    }

    function _swapTokensForUSDC(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
        
    }  

    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        require(holder != address(this) && !isMarketPair[holder]);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function removeStuckEth(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function removeStuckToken(IERC20 _token,uint256 amount) external onlyOwner {
        _token.transfer(msg.sender,amount);
    }

    function setMaxTxnAmount(uint256 amount) external onlyOwner {
        maxTxnAmount = amount;
    }

    function setMaxWalletAmount(uint256 amount) external onlyOwner {
        maxWalletAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function enableTxLimit(bool _status) external onlyOwner {
        EnableTxLimit = _status;
    }

    function enableWalletLimit(bool _status) external onlyOwner {
        checkWalletLimit = _status;
    }

    function setIsWalletExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isWalletLimitExempt[holder] = exempt;
    }

    function setIsBot(address holder, bool exempt)
        external
        onlyOwner
    {
        isBot[holder] = exempt;
    }

    function setMarketPair(address _pair, bool status) external onlyOwner {
        isMarketPair[address(_pair)] = status;
        if(status) {
            isDividendExempt[_pair] = status;
            isWalletLimitExempt[_pair] = status;
        }
    }

    function enableAutoReward(bool _status) external onlyOwner {
        ClaimableOnly = _status;
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas must be lower than 750000");
        distributorGas = gas;
    }
    
    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setMarketingWallet(address _newWallet) external onlyOwner {
        marketingWallet = _newWallet;
    }
    
    function setLiquidityWallet(address _newWallet) external onlyOwner {
        liquidityReciever = _newWallet;
    }

    function updateCoolDownTime(uint256 newCooldown) external onlyOwner {
        coolDownTime = newCooldown;
    }

    function toggleCoolDownActive() external onlyOwner {
        CoolDownActive = !CoolDownActive;
    }
  
    function rescueDividentToken(address tokenAddress,address _receiver, uint256 tokens) external onlyOwner returns (bool success) {
        return distributor.rescueToken(tokenAddress, _receiver,tokens);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setMinHoldingReward(uint _minHolding) external onlyOwner {
        distributor.setMinHolding(_minHolding);
    }

}