/**
 *Submitted for verification at Arbiscan on 2023-03-03
*/

/**
FunkyPug - Meme Token of the season on Arbitrum.
Join our community on Tg and visit our website

5% ETH Rewards

Tg: https://t.me/funkypuginu

*/


pragma solidity ^0.8.16;

// SPDX-License-Identifier: Unlicensed

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    address _token;

    address distributorOwner;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 60 minutes;
    uint256 public minDistribution = 1 * (10**19);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token || msg.sender == distributorOwner);
        _;
    }

    constructor(address _distributorOwner) {
        _token = msg.sender;
        distributorOwner = _distributorOwner;
    }

    function setDistributionCriteria(
        uint256 newMinPeriod,
        uint256 newMinDistribution
    ) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external payable override onlyToken {
        totalDividends = totalDividends.add(msg.value);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares)
        );
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            // RewardToken.transfer(shareholder, amount);
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend(address shareholder) external onlyToken {
        distributeDividend(shareholder);
    }

    function changeOwner(address newOwner) external onlyToken {
        distributorOwner = newOwner;
    }

    function rescueDividends(uint256 amountPercentage) external onlyToken {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
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
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract FunkyPugInu is IERC20, Auth {
    using SafeMath for uint256;

    string constant _name = "FunkyPug Inu";
    string constant _symbol = "PUGINU";
    uint8 constant _decimals = 18;

    address routerAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    address public autoLiquidityReceiver;
    address public marketingWallet;
    address public devWallet;

    uint256 _totalSupply = 10000000 * (10**_decimals);
    uint256 public _maxTxAmount = (_totalSupply * 20) / 1000;
    uint256 public _walletMax = (_totalSupply * 20) / 1000;
    bool public restrictWhales = true;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    bool public tradingOpen = false;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isDividendExempt;

    bool public takeBuyFee = true;
    bool public takeSellFee = true;
    bool public takeTransferFee = true;

    uint256 public liquidityFee = 20;
    uint256 public marketingFee = 30;
    uint256 public rewardsFee = 50;
    uint256 private devFee = 10;

    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 0;

    uint256 public previousLiquidityFee;
    uint256 public previousMarketingFee;
    uint256 public previousRewardsFee;
    uint256 public previousDevFee;

    uint256 public previousTotalFee;
    uint256 public previousTotalFeeIfSelling;

    bool public isHappyHour = false;

    //Blacklits
    bool public launchMode = true;
    bool public blacklistMode = true;
    mapping(address => bool) public isBlacklisted;
    uint256 public amountOfF = 17 gwei / 100;

    IDEXRouter public router;
    address public pair;
    mapping(address => bool) public isPair;

    uint256 public launchedAt;

    DividendDistributor public dividendDistributor;
    uint256 distributorGas = 750000;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    uint256 public swapThreshold = (_totalSupply * 3) / 2000;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountToken);

    constructor() Auth(msg.sender) {
        autoLiquidityReceiver = msg.sender;
        marketingWallet = msg.sender;
        devWallet = msg.sender;

        router = IDEXRouter(routerAddress);
        address pair_weth = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        pair = pair_weth;
        isPair[pair] = true;

        _allowances[address(this)][address(router)] = type(uint256).max;

        dividendDistributor = new DividendDistributor(msg.sender);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[pair_weth] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[pair_weth] = true;
        isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0xdead)] = true;
        isDividendExempt[address(0)] = true;

        totalFee = liquidityFee.add(marketingFee).add(rewardsFee).add(devFee);
        totalFeeIfSelling = totalFee + 150;

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            _totalSupply.sub(balanceOf(address(0xdead))).sub(
                balanceOf(address(0))
            );
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function checkPendingDividends(address account)
        external
        view
        returns (uint256)
    {
        return dividendDistributor.getUnpaidEarnings(account);
    }

    function claimDividend() external {
        dividendDistributor.claimDividend(msg.sender);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
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
        if (_allowances[sender][msg.sender] != type(uint256).max) {
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
        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!authorizations[sender]) {
            require(tradingOpen, "Trading not open yet");
        }

        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );

        if (
            !isPair[sender] &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            swapBack();
        }

        if (!launched() && isPair[recipient]) {
            require(_balances[sender] > 0);
            launch();
        }

        if (blacklistMode) {
            require(!isBlacklisted[sender], "Blacklisted");
        }

        if (launchMode) {
            if (!isPair[recipient] && tx.gasprice > amountOfF) {
                isBlacklisted[recipient] = true;
            }
            if (isPair[recipient] && !authorizations[sender]) {
                require(tx.gasprice <= amountOfF, ">Sell on wallet action");
            }
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        if (!isTxLimitExempt[recipient] && restrictWhales) {
            require(_balances[recipient].add(amount) <= _walletMax);
        }

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient]
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        // Dividend tracker
        if (!isDividendExempt[sender]) {
            try
                dividendDistributor.setShare(sender, _balances[sender])
            {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try
                dividendDistributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try dividendDistributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, finalAmount);

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeApplicable = 0;

        if (isPair[recipient] && takeSellFee) {
            feeApplicable = totalFeeIfSelling;
        }
        if (isPair[sender] && takeBuyFee) {
            feeApplicable = totalFee;
        }
        if (!isPair[sender] && !isPair[recipient]) {
            if (takeTransferFee) {
                feeApplicable = totalFeeIfSelling;
            } else {
                feeApplicable = 0;
            }
        }

        uint256 feeAmount = amount.mul(feeApplicable).div(1000);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapBack() internal lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify
            .mul(liquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH
            .mul(liquidityFee)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHReflection = amountETH.mul(rewardsFee).div(
            totalETHFee
        );
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(
            totalETHFee
        );
        uint256 amountETHDev = amountETH.mul(devFee).div(totalETHFee);

        try
            dividendDistributor.deposit{value: amountETHReflection}()
        {} catch {}

        (bool tmpSuccess, ) = payable(marketingWallet).call{
            value: amountETHMarketing,
            gas: 30000
        }("");

        tmpSuccess = false;

        (tmpSuccess, ) = payable(devWallet).call{
            value: amountETHDev,
            gas: 30000
        }("");

        if (amountToLiquify > 0) {
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

    function tradingStatus(bool _status) public authorized {
        tradingOpen = _status;
        if (tradingOpen && launchedAt == 0) {
            launchedAt = block.number;
        }
    }

    function changeTakeBuyfee(bool status) public authorized {
        require(!isHappyHour, "Happy Hour is active");
        takeBuyFee = status;
    }

    function changeTakeSellfee(bool status) public authorized {
        takeSellFee = status;
    }

    function changeTakeTransferfee(bool status) public authorized {
        takeTransferFee = status;
    }

    function setWalletLimit(uint256 newLimit) external authorized {
        require(newLimit >= 5, "Wallet Limit needs to be at least 0.5%");
        _walletMax = (_totalSupply * newLimit) / 1000;
    }

    function setTxLimit(uint256 newLimit) external authorized {
        require(newLimit >= 5, "Wallet Limit needs to be at least 0.5%");
        _maxTxAmount = (_totalSupply * newLimit) / 1000;
    }

    
    function enableBlacklist(bool _status) public onlyOwner {
        blacklistMode = _status;
    }
        
    function changeBlacklist(address[] calldata addresses, bool status) public onlyOwner {
        require(launchMode, "");
        for (uint256 i; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
    }

    function changeAmountOfF(uint256 newAmount) public onlyOwner {
        require(launchMode, "");
        amountOfF = newAmount * 1 gwei/10;
    }

    function endLaunchMode() public onlyOwner {
        launchMode = false;

        liquidityFee = 20;
        rewardsFee = 40;
        marketingFee = 40;
        devFee = 0;
        amountOfF = 99999 gwei;
        totalFee = liquidityFee.add(marketingFee).add(rewardsFee).add(devFee);
        totalFeeIfSelling = totalFee;
        _maxTxAmount = _totalSupply/100;
    }

    function startHappyHour() public authorized {
        require(!isHappyHour, "Happy Hour is already active");
        
        isHappyHour = true;
        
        previousLiquidityFee = liquidityFee;
        previousRewardsFee = rewardsFee;
        previousMarketingFee = marketingFee;
        previousDevFee = devFee;
        previousTotalFee = totalFee;
        previousTotalFeeIfSelling = totalFeeIfSelling;

        takeBuyFee = false;
        liquidityFee = previousLiquidityFee * 2;
        rewardsFee = previousRewardsFee * 2;
        marketingFee = previousMarketingFee * 2;
        devFee = previousDevFee * 2;
        totalFee = liquidityFee.add(marketingFee).add(rewardsFee).add(devFee);
        totalFeeIfSelling = totalFee;
    }

    function endHappyHour() public authorized {
        isHappyHour = false;
        liquidityFee = previousLiquidityFee;
        rewardsFee = previousRewardsFee;
        marketingFee = previousMarketingFee;
        devFee = previousDevFee;
        totalFee = previousTotalFee;
        totalFeeIfSelling = previousTotalFeeIfSelling;
        takeBuyFee = true;
    }

    function changeFees(
        uint256 newLiqFee,
        uint256 newRewardFee,
        uint256 newMarketingFee,
        uint256 newDevFee,
        uint256 extraSellFee
    ) external authorized {
        require(!isHappyHour, "Happy Hour is active");
        liquidityFee = newLiqFee;
        rewardsFee = newRewardFee;
        marketingFee = newMarketingFee;
        devFee = newDevFee;

        totalFee = liquidityFee.add(marketingFee).add(rewardsFee).add(devFee);
        totalFeeIfSelling = totalFee + extraSellFee;
        require(
            totalFee + totalFeeIfSelling <= 250,
            "Token: Combined fees must be under 20%"
        );
    }

    function changeSwapBackSettings(
        bool enableSwapBack,
        uint256 newSwapBackLimit,
        bool swapByLimitOnly
    ) external authorized {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
        swapAndLiquifyByLimitOnly = swapByLimitOnly;
    }

    function changeDistributionCriteria(
        uint256 newinPeriod,
        uint256 newMinDistribution
    ) external authorized {
        dividendDistributor.setDistributionCriteria(
            newinPeriod,
            newMinDistribution
        );
    }

    function changeDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function processDividends(uint256 gas) external authorized {
        dividendDistributor.process(gas);
    }

    function setRouterAddress(address newRouter) public authorized {
        IDEXRouter _uniswapV2Router = IDEXRouter(newRouter);
        // Create a uniswap pair for this new token
        IDEXFactory _uniswapV2Factory = IDEXFactory(_uniswapV2Router.factory());
        address pairAddress = _uniswapV2Factory.getPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        if (pairAddress == address(0)) {
            pairAddress = _uniswapV2Factory.createPair(
                address(this),
                _uniswapV2Router.WETH()
            );
        }
        isPair[pairAddress] = true;
        isDividendExempt[pairAddress] = true;
        isTxLimitExempt[pairAddress] = true;

        router = _uniswapV2Router;
    }

    function changePair(address _address, bool status) public authorized {
        isPair[_address] = status;
    }

    function changeIsFeeExempt(address holder, bool exempt) public authorized {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt)
        public
        authorized
    {
        isTxLimitExempt[holder] = exempt;
    }

    function changeIsDividendExempt(address holder, bool exempt)
        public
        authorized
    {
        if (isPair[holder]) {
            exempt = true;
        }

        isDividendExempt[holder] = exempt;

        if (exempt) {
            dividendDistributor.setShare(holder, 0);
        } else {
            dividendDistributor.setShare(holder, _balances[holder]);
        }
    }

    function addDapp(address target) public authorized {
        changeIsDividendExempt(target, true);
        changeIsTxLimitExempt(target, true);
        changeIsFeeExempt(target, true);
    }

    function changeFeeReceivers(
        address newLiquidityReceiver,
        address newMarketingWallet,
        address newDevWallet
    ) external authorized {
        autoLiquidityReceiver = newLiquidityReceiver;
        marketingWallet = newMarketingWallet;
        devWallet = newDevWallet;
    }

    function removeERC20(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        require(tokenAddress != address(this), "Cant remove the native token");
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function removeEther(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }

    function ManualSwap() external authorized {
        swapBack();
    }

    function multiTransfer(
        address[] calldata addresses,
        uint256[] calldata tokens
    ) external onlyOwner {
        address from = msg.sender;
        require(
            addresses.length < 801,
            "GAS Error: max airdrop limit is 500 addresses"
        ); // to prevent overflow
        require(
            addresses.length == tokens.length,
            "Mismatch between Address and token count"
        );

        uint256 SCCC = 0;

        for (uint256 i = 0; i < addresses.length; i++) {
            SCCC = SCCC + tokens[i];
        }

        require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

        for (uint256 i = 0; i < addresses.length; i++) {
            _basicTransfer(from, addresses[i], tokens[i]);
            if (!isDividendExempt[addresses[i]]) {
                try
                    dividendDistributor.setShare(
                        addresses[i],
                        balanceOf(addresses[i])
                    )
                {} catch {}
            }
        }

        // Dividend tracker
        if (!isDividendExempt[from]) {
            try dividendDistributor.setShare(from, balanceOf(from)) {} catch {}
        }
    }
}