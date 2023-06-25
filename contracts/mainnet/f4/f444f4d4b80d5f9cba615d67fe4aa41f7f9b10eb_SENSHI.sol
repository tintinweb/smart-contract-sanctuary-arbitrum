/**
 *Submitted for verification at Arbiscan on 2023-06-25
*/

// ██████  ███████ ██    ██  ██████  ██      ██    ██ ███████ ██  ██████  ███    ██                   
// ██   ██ ██      ██    ██ ██    ██ ██      ██    ██     ██  ██ ██    ██ ████   ██                  
// ██████  █████   ██    ██ ██    ██ ██      ██    ██   ██    ██ ██    ██ ██ ██  ██                   
// ██   ██ ██       ██  ██  ██    ██ ██      ██    ██  ██     ██ ██    ██ ██  ██ ██                   
// ██   ██ ███████   ████    ██████  ███████  ██████  ███████ ██  ██████  ██   ████              

//Revoluzion Ecosystem
//WEB: https://revoluzion.io
//DAPP: https://revoluzion.app

// Contract fixed by Revoluzion

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

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

}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    
    using SafeMath for uint256;

    address public immutable token;
    address public immutable projectOwner;
    address public distributorNew;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 public constant ARB = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);  //ARB mainnet arbiscan
    
    bool public upgraded = false;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public currentIndex;

    uint256 public constant ACCURACYFACTOR = 10 ** 27;
    
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 17);

    IDexRouter public immutable router;    

    modifier onlyToken() {
        if (upgraded) {
            require(msg.sender == projectOwner);
        } else {
            require(msg.sender == token);
        }
        _;
    }

    constructor (address _router, address tokenAdr, address projectOwnerAdr) {
        router = _router != address(0)
        ? IDexRouter(_router)
        : IDexRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        token = tokenAdr;
        projectOwner = projectOwnerAdr;
    }

    event UpdateDistributionCriteria(uint256 minPeriodNew, uint256 minDistributionNew);

    function setDistributionCriteria(uint256 minPeriodNew, uint256 minDistributionNew) external override onlyToken {
        minPeriod = minPeriodNew;
        minDistribution = minDistributionNew;
        emit UpdateDistributionCriteria(minPeriodNew, minDistributionNew);
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

    function rescueToken(address tokenAddress, address receiver, uint256 tokens) external onlyToken returns (bool success){
        if (tokenAddress == token) {
            require(upgraded, "Cannot withdraw SENSHI if this dividend smart contract is still in use.");
        }
        return IERC20(tokenAddress).transfer(receiver, tokens);
    }

    function withdrawFunds(address receiver, uint256 value) external onlyToken {
        require(receiver != address(0), "Cannot send funds to zero address");
        payable(receiver).transfer(value);
    }

    function changeDividendDistributor(address newDistributor) external onlyToken {
        require(!upgraded, "Cannot change to other distributor smart contract since this smart contract has been upgraded.");
        require(newDistributor != address(0), "Cannot set new distributor as zero address");
        upgraded = true;
        distributorNew = newDistributor;
    }

    function deposit() external override payable onlyToken {
        uint256 balanceBefore = ARB.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(ARB);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
        
        uint256 amount = ARB.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(ACCURACYFACTOR.mul(amount).div(totalShares));
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
        return shareholderClaims[shareholder] + minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            require(ARB.transfer(shareholder, amount), "There's something wrong with token transfer");
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
        return share.mul(dividendsPerShare).div(ACCURACYFACTOR);
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


contract SENSHI is IERC20, Ownable {

    using SafeMath for uint256;

    string private constant NAME = "SENSHI";
    string private constant SYMBOL = "SENSHI";
    uint8 private constant DECIMALS = 9;

    uint256 private constant TOTALSUPPLY = 1_000_000_000 * 10**DECIMALS;
    
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);

    address public marketingWallet = address(0xe4Bd88F19C9BA30782F3439169dd0D2F5702D0Ef);
    
    uint256 public buyMarketingFee = 20;
    uint256 public buyRewardFee = 30;

    uint256 public sellMarketingFee = 20;
    uint256 public sellRewardFee = 30;

    uint256 public totalBuyFee;
    uint256 public totalSellFee;

    uint256 public constant DENOMINATOR = 1000;

    DividendDistributor public distributor;

    uint256 public swapThreshold = 50_000 * 10**DECIMALS;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isMarketPair;

    IDexRouter public immutable router;
    address public immutable pair;
    
    bool public swapEnabled = true;
    bool public claimableOnly = false;  
    uint256 distributorGas = 500_000;

    bool inSwap;
    
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event UpdateBuyFee(uint newMarket, uint newReward);

    event UpdateSellFee(uint newMarket, uint newReward);

    event UpdateDistributionCriteria(uint256 minPeriodNew, uint256 minDistributionNew);

    event UpdateDistributorSettings(uint256 amount);

    event SwapEnabledUpdated(bool enabled);
    
    event SwapTokensForETH(uint256 amountIn, address[] path);

    constructor() Ownable() {

        address developer = 0x6A186fe003ec8E3467f527a57595913e322AF615;
   
        address router_ = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;  //app.sushi.com router

        router = IDexRouter(router_);
        
        pair = IDexFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        distributor = new DividendDistributor(router_, address(this), _msgSender());

        isFeeExempt[marketingWallet] = true;
        isFeeExempt[developer] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(router)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[address(router)] = true;
        isDividendExempt[address(distributor)] = true;

        isMarketPair[address(pair)] = true;

        _allowances[address(this)][address(router)] = ~uint256(0);
        _allowances[address(this)][address(pair)] = ~uint256(0);

        totalBuyFee = buyMarketingFee.add(buyRewardFee);
        totalSellFee = sellMarketingFee.add(sellRewardFee);

        transferOwnership(developer);

        _balances[developer] = TOTALSUPPLY;
        emit Transfer(address(0), developer, TOTALSUPPLY);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return TOTALSUPPLY;
    }

    function decimals() external pure override returns (uint8) {
        return DECIMALS;
    }

    function symbol() external pure override returns (string memory) {
        return SYMBOL;
    }

    function name() external pure override returns (string memory) {
        return NAME;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return TOTALSUPPLY.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
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
        address provider,
        address spender,
        uint256 amount
    ) internal virtual {
        require(provider != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[provider][spender] = amount;
        emit Approval(provider, spender, amount);
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
        if (_allowances[sender][msg.sender] != TOTALSUPPLY) {
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
    

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        else {

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;

            if (overMinimumTokenBalance && !inSwap && !isMarketPair[sender] && swapEnabled) {
                swapBack(swapThreshold);
            }
            
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldNotTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient].add(finalAmount);
        
            if (!isDividendExempt[sender]) {
                try distributor.setShare(sender, _balances[sender]) {} catch {}
            }
            if (!isDividendExempt[recipient]) {
                try distributor.setShare(recipient, _balances[recipient]) {} catch {}
            }

            if(!claimableOnly)  try distributor.process(distributorGas) {} catch {}

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
        
        uint feeAmount = 0;

        unchecked {

            if(isMarketPair[sender]) { //buy
                feeAmount = amount.mul(totalBuyFee).div(DENOMINATOR);
            } 
            else if(isMarketPair[recipient]) { //sell
                feeAmount = amount.mul(totalSellFee).div(DENOMINATOR);
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

        uint256 _MarketingShare = buyMarketingFee.add(sellMarketingFee);

        uint256 tokensForSwap = contractBalance;

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance.sub(initialBalance);

        uint256 amountETHMarketing = amountReceived.mul(_MarketingShare).div(totalShares);
        uint256 amountETHReward = amountReceived.sub(amountETHMarketing);

        if(amountETHMarketing > 0) {
            payable(marketingWallet).transfer(amountETHMarketing);
        }
    
        if(amountETHReward > 0) {
            try distributor.deposit { value: amountETHReward } () {} catch {}
        }

    }

   function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        emit SwapTokensForETH(tokenAmount, path);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
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

    function removeStuckToken(IERC20 token,uint256 amount) external onlyOwner {
        require(address(token) != address(this), "Cannot withdraw SENSHI from the smart contract.");
        require(token.transfer(msg.sender,amount), "Something is wrong with the transfer.");
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setMarketPair(address adr, bool status) external onlyOwner {
        isMarketPair[address(adr)] = status;
        if(status) {
            isDividendExempt[adr] = status;
        }
    }

    function setDistributor(DividendDistributor newDistributor) external onlyOwner {
        require(distributor != newDistributor, "This is the current distributor being used");
        require(address(newDistributor) != ZERO, "Cannot set as zero address");
        require(address(newDistributor) != DEAD, "Cannot set as dead address");
        DividendDistributor oldDistributor = distributor;
        distributor = newDistributor;
        isDividendExempt[address(newDistributor)] = true;
        oldDistributor.changeDividendDistributor(address(newDistributor));
    }

    function enableAutoReward(bool status) external onlyOwner {
        claimableOnly = status;
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas must be lower than 750000");
        require(gas != distributorGas, "This is the current value for distributor gas");
        distributorGas = gas;
        emit UpdateDistributorSettings(gas);
    }
    
    function setSwapBackSettings(bool enabled, uint256 amount)
        external
        onlyOwner
    {
        swapEnabled = enabled;
        swapThreshold = amount;
        emit SwapEnabledUpdated(enabled);
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        require(marketingWallet != newWallet, "This is the current address being used");
        require(marketingWallet != ZERO, "Cannot set as zero address");
        require(marketingWallet != DEAD, "Cannot set as dead address");
        marketingWallet = newWallet;
    }

    function setBuyFee(uint newMarket, uint newReward) external onlyOwner {
        require(newMarket.add(newReward) <= 100, "Total buy fee cannot exceed 10%");
        buyMarketingFee = newMarket;
        buyRewardFee = newReward;
        totalBuyFee = buyMarketingFee.add(buyRewardFee);
        emit UpdateBuyFee(newMarket, newReward);
    }

    function setSellFee(uint newMarket, uint newReward) external onlyOwner {
        require(newMarket.add(newReward) <= 100, "Total buy fee cannot exceed 10%");
        sellMarketingFee = newMarket;
        sellRewardFee = newReward;
        totalSellFee = sellMarketingFee.add(sellRewardFee);
        emit UpdateSellFee(newMarket, newReward);
    }
  
    function rescueDividentToken(address tokenAddress, address receiver, uint256 tokens) external onlyOwner returns (bool success) {
        if (tokenAddress == address(this)) {
            require(distributor.upgraded(), "Cannot withdraw SENSHI if dividend smart contract is still in use.");
        }
        return distributor.rescueToken(tokenAddress, receiver,tokens);
    }

    function rescueDividentFunds(address receiver, uint256 value) external onlyOwner {
        distributor.withdrawFunds(receiver, value);
    }

    function setDistributionCriteria(uint256 minPeriodNew, uint256 minDistributionNew) external onlyOwner {
        emit UpdateDistributionCriteria(minPeriodNew, minDistributionNew);
        distributor.setDistributionCriteria(minPeriodNew, minDistributionNew);
    }

}